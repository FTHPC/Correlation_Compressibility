#!/usr/bin/env julia
using CUDA
using Base.Iterators
using LinearAlgebra
using JSON
using GPUArrays
using MKL
using CSV
using DataFrames


unfold(x; dims=1) = hcat(collect.(flatten.(eachslice(x; dims=dims)))...)'

function unfold_web(A::Array{T,N};dims::Integer = 1) where {T<:Number,N}
    #https://github.com/Jutho/TensorOperations.jl/issues/13#issuecomment-214028135
    B = permutedims(A,vcat(dims,setdiff(1:N,dims)))
    d = size(B,1)
    return reshape(B,(d,div(length(B),d)))
end


function _cuda_svd_unfold(data, i)
      uf = unfold_web(data; dims=i);
      result = svd(CuArray(uf));
      host_s = Array{eltype(uf)}(undef, size(result.S)...)
      copyto!(host_s, result.S)
      return host_s
end
function cuda_svd_trunc(data)
    sing = Array{Array{Float64,1},1}(undef, 3)
    @sync begin
        Threads.@spawn begin
            sing[1] = _cuda_svd_unfold(data, 1)
            nothing
        end
        Threads.@spawn begin
            sing[2] = _cuda_svd_unfold(data, 2)
            nothing
        end
        Threads.@spawn begin
            sing[3] = _cuda_svd_unfold(data, 3)
            nothing
        end
    end
    return sing
end

function cpu_svd_trunc(data)
    sing = Array{Array{Float64,1},1}()
    for i in 1:3
      uf = unfold_web(data; dims=i);
      result = svd(uf);
      push!(sing, result.S)
    end
    return sing
end


function main()
    filename = ARGS[1]
    output   = ARGS[2]
    vers     = ARGS[3]
    dims     = parse.(Int, ARGS[4:end])
    data     = Array{Float64}(undef, dims...)
    read!(filename, data)

    # TODO:: GPU argument (-g) switches the GPU version on
    if (vers == 0) 
        sing = cuda_svd_trunc(data)
    else 
        sing = cpu_svd_trunc(data)
    end
    #combine singular values into one array
    sv0 = Array{Float64,1}()
    sv1 = Array{Float64,1}()

    for i in 1:3
        for j in 1:2
            push!(sv0, sing[i][j])
        end 
    end

    for i in 1:3
        for j in 3:dims[i]
            push!(sv1, sing[i][j])
        end 
    end


    ## TODO: Implement this R code for new singular values merging.

    # num_modes <- tnsr@num_modes   
    # sv_list <- vector("list", num_modes)
    # sv_contrib_list <- vector("list", num_modes)
    # u_list <- vector("list", num_modes)
    # trunc_list <- vector("list", num_modes)
    # ind_trunc_list <- vector("list", num_modes)
    # for (m in 1:num_modes) {
    # temp_mat <- k_unfold(tnsr, m = m)@data
    # svdi <- svd(temp_mat)
    # di <- svdi$d
    # u_list[[m]] <- svdi$u
    # sv_list[[m]] <- di
    # sv_contrib_list[[m]] <- cumsum(di^2)/sum(di^2) 
    # trunc_list[[m]] <- min(which(sv_contrib_list[[m]]>0.999)) 
    # ind_trunc_list[[m]] <- 1:(trunc_list[[m]])  }  

    sort!(sv1, rev=true);

    sorted = Array{Float64,1}()
    #combines sv0 and sv1 into a 1D singular value array
    sorted = vcat(sv0, sv1)

    open(output, "w") do io
        write(io, sorted)
    end;
    
end

main()
	
