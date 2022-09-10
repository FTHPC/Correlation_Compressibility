#!/usr/bin/env julia

using StatsPlots
using DataFrames
using CSV
using Statistics

df = DataFrame(CSV.File("speed_results_0.01.csv"));
df[!,"time"] = df[!,"time_ns"] / 10^6;
summary = combine(groupby(df, [:device, :metric]), :time => std, :time => mean)
df = innerjoin(df,summary , on=[:device,:metric]);
@df df groupedbar(:metric, :time, group=:device, yerr=:time_std, xlabel="metric", ylabel="time (ms)", dpi=300);
png("/tmp/speedup_e2.png");