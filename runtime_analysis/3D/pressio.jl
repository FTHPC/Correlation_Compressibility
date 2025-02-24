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

function quantize_kernel(cu_data, global_bins, N::Int64, dmin::Float32, abs::Float32)
  global_idx = threadIdx().x + blockDim().x * (blockIdx().x -1)
  if global_idx <= N
    bin_idx = trunc(Int32,(cu_data[global_idx] - dmin)/abs) + 1
    @inbounds CUDA.@atomic global_bins[bin_idx] += 1
  end
  return
end
function extreem(x:: Tuple{T,T}, y:: T)::Tuple{T,T} where{T}
  (min_x, max_x) = x;
  return (min(min_x, y), max(max_x, y))
end
function extreem(x:: T, y:: Tuple{T,T})::Tuple{T,T} where{T}
  (min_y, max_y) = y;
  return (min(x, min_y), max(x, max_y))
end
function extreem(x:: Tuple{T,T}, y:: Tuple{T,T})::Tuple{T,T} where{T}
  (min_x, max_x) = x;
  (min_y, max_y) = y;
  return (min(min_x, min_y), max(max_x, max_y))
end
GPUArrays.neutral_element(::typeof(extreem), T) = (floatmax(T), floatmin(T))
function cuda_qentropy(data; abs=1e-4)
  cu_data = CuArray(data);
  N = length(cu_data)
  (dmin,dmax) = reduce(extreem, cu_data; init=(floatmax(eltype(data)),floatmin(eltype(data))))
  bin_counts = round(Int64,(dmax-dmin)/abs) + 1
  bins = CUDA.zeros(Int32, bin_counts)
  n_threads=32
  n_blocks=trunc(Int,(N + n_threads+1) / n_threads)
  @cuda threads=n_threads blocks=n_blocks quantize_kernel(cu_data, bins, N, dmin, abs)
  -mapreduce(+, bins; init=0.0) do bin
    if bin != 0
      prop = convert(Float64,bin)/N;
      prop * log2(prop)
    else
      0.0
    end
  end
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

function cpu_qentropy(data; abs=1e-4)
  N = length(data)
  (dmin,dmax) = reduce(extreem, data; init=(floatmax(Float32),floatmin(Float32)))
  bin_counts = round(Int64,(dmax-dmin)/abs) + 1
  bins = zeros(Int32, bin_counts)
  for value in data
    bin_idx = trunc(Int32,(value - dmin)/abs) + 1
    @inbounds bins[bin_idx] += 1
  end
  -mapreduce(+, bins; init=0.0) do bin
    if bin != 0
      prop = convert(Float64,bin)/N;
      prop * log2(prop)
    else
      0.0
    end
  end
end

function main()
    filename = ARGS[1]
    bound = parse(Float32, ARGS[2])
    dims = parse.(Int, ARGS[3:end])
    data = Array{Float32}(undef, dims...)
    read!(filename, data)

    cpu_q_times = []
    cpu_s_times = []
    cuda_q_times = []
    cuda_s_times = []
    for i = 1:8
        cuda_s_begin = time_ns()
        sing = cuda_svd_trunc(data)
        cuda_s_end = time_ns()

        cuda_q_begin = time_ns()
        qentropy = cuda_qentropy(data; abs=bound)
        cuda_q_end = time_ns()

        cpu_s_begin = time_ns()
        sing = cpu_svd_trunc(data)
        cpu_s_end = time_ns()

        cpu_q_begin = time_ns()
        qentropy = cpu_qentropy(data; abs=bound)
        cpu_q_end = time_ns()

        if i > 1
            push!(cuda_s_times, cuda_s_end-cuda_s_begin)
            push!(cuda_q_times, cuda_q_end-cuda_q_begin)
            push!(cpu_s_times, cpu_s_end-cpu_s_begin)
            push!(cpu_q_times, cpu_q_end-cpu_q_begin)
        end
        println("done")
    end
    
    result = Dict(
              "cuda_singular_modes_ns" => cuda_s_times,
              "cpu_singular_modes_ns" => cpu_s_times,
              "dataset" => filename,
              "cuda_qentropy_ns" => cuda_q_times,
              "cpu_qentropy_ns" => cpu_q_times,
             )
    println(JSON.json(result))
    df = DataFrame( time_ns = cuda_s_times,
                    device = "cuda",
                    metric = "HOSVD",
                    bound = bound,
                    dataset = filename,
    )
    CSV.write("speed_results_" * string(bound) * ".csv", df)

    df = DataFrame( time_ns = cpu_s_times,
                    device = "cpu",
                    metric = "HOSVD",
                    bound = bound,
                    dataset = filename,
    )
    CSV.write("speed_results_" * string(bound) * ".csv", df, append=true, writeheader=false)
    
    df = DataFrame( time_ns = cuda_q_times,
                    device = "cuda",
                    metric = "qentropy",
                    bound = bound,
                    dataset = filename,
    )
    CSV.write("speed_results_" * string(bound) * ".csv", df, append=true, writeheader=false)

        
    df = DataFrame( time_ns = cpu_q_times,
                    device = "cpu",
                    metric = "qentropy",
                    bound = bound,
                    dataset = filename,
    )
    CSV.write("speed_results_" * string(bound) * ".csv", df, append=true, writeheader=false)
end

main()
	
