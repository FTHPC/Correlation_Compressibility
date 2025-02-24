#!/usr/bin/env python
import pandas as pd
import numpy as np
import time
from numpy.polynomial import Polynomial
from scipy.optimize import minimize
import matplotlib.pyplot as plt
import dlib
import random

X = "config:bound"
Y = "size:compression_ratio"
Z = "error_stat:psnr"

def make_linear_proxy(df: pd.DataFrame, x_col: str, y_col: str):
    local_df = df.sort_values(x_col).reset_index(drop=True)
    lower_bound = local_df[x_col].min()
    upper_bound = local_df[x_col].max()

    def proxy(x: float) -> float:
        assert lower_bound <= x <= upper_bound, "out of bounds"
        idx = np.searchsorted(local_df[x_col], x)
        if idx == 0: 
            return np.inf  
        if idx == len(local_df):
            if local_df.iloc[idx - 1, local_df.columns.get_loc(x_col)] == x:
                return local_df.iloc[idx - 1, local_df.columns.get_loc(y_col)]
            else: 
                return np.inf  
        if local_df.iloc[idx, local_df.columns.get_loc(x_col)].item() == x:
            return local_df.iloc[idx, local_df.columns.get_loc(y_col)].item()

        lower_x = local_df.iloc[idx - 1, local_df.columns.get_loc(x_col)].item()
        lower_y = local_df.iloc[idx - 1, local_df.columns.get_loc(y_col)].item()
        upper_x = local_df.iloc[idx, local_df.columns.get_loc(x_col)].item()
        upper_y = local_df.iloc[idx, local_df.columns.get_loc(y_col)].item()

        return np.interp(x, [lower_x, upper_x], [lower_y, upper_y])

    return proxy

def make_polynomial_proxy(df: pd.DataFrame, x_col: str, y_col: str, deg):
    local_df = df.sort_values(x_col)
    lower_bound = df[x_col].min()
    upper_bound = df[x_col].max()
    x_vals = df[x_col]
    y_vals = df[y_col]
    poly = Polynomial.fit(x_vals,y_vals,deg)
    def polynomial(x: float) -> float:
        return poly([x])[0]
    return polynomial

def make_inverted_objective(proxy):
    def inverted(x):
        return -proxy(x)
    return inverted

#def on_error(f, on_error):
def on_error(f, on_error):

    def g(*args):
        try:
            return f(*args)
        except:
            return on_error
    return g

def make_acc_fidelity(proxy):
    def high(x: float) -> float:
        time.sleep(1000/1_000_000_000)
        return proxy(x)
    return high

def make_approx_fidelity(proxy,scale):
    noise_db = {}
    def low(x: float) -> float:
        nonlocal noise_db
        if x not in noise_db:
            noise = np.random.normal(scale=scale)
            noise_db[x] = noise
        else:
            noise = noise_db[x]
        y = proxy(x) + noise
        return y 
    return low

def make_callback(proxy,target):

    def callback(x):
        start = time.perf_counter()
        y = proxy(x)
        end = time.perf_counter()
        callback.iter = callback.iter + 1
        callback.history.append((x, y))
        callback.timing.append((end - start))
        #diff = y - target
        diff = y - target
        #callback.diffs.append(y - target)
        callback.diffs.append(y - target)
        #diff = (y - target)**2
        print(f"Iteration {callback.iter}: Current eb = {x}, Pred CR = {y}, diff = {diff}, time = {end - start}")
        return abs(diff)

    def reset():
        nonlocal callback
        callback.timing = []
        callback.history = []
        callback.diffs = []
        callback.iter = 0
       
    def reset_iter():
        callback.iter = 0
    
    callback.reset = reset
    callback.reset_iter = reset_iter
    callback.timing = []
    callback.history = []
    callback.diffs = []
    callback.iter = 0
    return callback

def make_polynomial_callback(proxy,target):

    def callback(x):
        start = time.perf_counter()
        y = proxy(x)
        end = time.perf_counter()
        callback.iter = callback.iter + 1
        callback.history.append((x, y))
        callback.timing.append((end - start))
        diff = target - y
        callback.diffs.append(target - y)
        #diff = (y - target)**2
        print(f"Iteration {callback.iter}: Current eb = {x}, Pred CR = {y}, diff = {diff}, time = {end - start}")
        return diff

    def reset():
        nonlocal callback
        callback.timing = []
        callback.history = []
        callback.diffs = []
        callback.iter = 0
       
    def reset_iter():
        callback.iter = 0
    
    callback.reset = reset
    callback.reset_iter = reset_iter
    callback.timing = []
    callback.history = []
    callback.diffs = []
    callback.iter = 0
    return callback


def brents(objective,x0,x1,max_iters,tolerance=1e-5):
    fx0 = objective(x0)
    fx1 = objective(x1)

    #print(f'x0: {x0}, f(x0): {fx0}, x1: {x1}, fx1: {fx1}')

    assert (fx0*fx1) <= 0, "Root not bracketed"

    if abs(fx0) < abs(fx1):
        x0, x1 = x1, x0
        fx0, fx1 = fx1, fx0

    x2, fx2 = x0, fx0

    mflag = True
    iters = 0

    # note that iters from callback will be > iters in this method
    # because we call the objective function 3x per iteration
    while iters < max_iters and abs(x1 - x0) > tolerance:
        fx0 = objective(x0)
        fx1 = objective(x1)
        fx2 = objective(x2)

        if fx0 != fx2 and fx1 != fx2:
            L0 = (x0 * fx1 * fx2) / ((fx0 - fx1) * (fx0 - fx2))
            L1 = (x1 * fx0 * fx2) / ((fx1 - fx0) * (fx1 - fx2))
            L2 = (x2 * fx1 * fx0) / ((fx2 - fx0) * (fx2 - fx1))
            new = L0 + L1 + L2
        else:
            new = x1 - ((fx1 * (x1 - x0)) / (fx1 - fx0))

        if ((new < ((3 * x0 + x1) / 4) or new > x1) or
            (mflag == True and (abs(new - x1)) >= (abs(x1 - x2) / 2)) or
            (mflag == False and (abs(new - x1)) >= (abs(x2 - d) / 2)) or
            (mflag == True and (abs(x1 - x2)) < tolerance) or
            (mflag == False and (abs(x2 - d)) < tolerance)):
            new = (x0 + x1) / 2
            mflag = True
        else:
            mflag = False

        fnew = objective(new)
        d, x2 = x2, x1

        if (fx0 * fnew) < 0:
            x1 = new
        else:
            x0 = new

        if abs(fx0) < abs(fx1):
            x0, x1 = x1, x0

        iters = iters + 1

    return fx1, x1
    #return x1, iters


def binary_search(low,high,threshold,objective,max_iters,max_searches,tolerance=1e-5):
    iters = 0
    closest_pred = np.inf
    closest_x = 0
    while iters < max_searches:
        mid = (high + low) / 2
        if iters > max_iters:
            break
        iters = iters + 1
        result = dlib.find_min_global(
                objective,
                [low], [high],
                max_iters
            )
        x = result[0][0]
        y = result[1]
        objective.reset_iter()
        if y < closest_pred:
            closest_pred = y
            closest_x = x
        print(f"high: {high}, low: {low}, x: {x}, y: {y}")
        if y < threshold:
            print(f'result: {result}')
            return result
        if x < mid:
            high = mid
        else:
            low = mid
        if high - low < tolerance:
            break
    print(f'unable to satisfy threshold. returning closest estimation.')
    return closest_pred,closest_x


df = pd.read_csv("results.csv", index_col=0)
lower_bound = df[X].min()
upper_bound = df[X].max()
df = df.sort_values(X)

orig_x = df[X]
orig_y = df[Y]
orig_z = df[Z]

sd = 5
deg = 7
max_iters = 10# 30
max_searches = 5#10
x0 = df.sample(n=1)[X].item()
cr_min = df[Y].min()
#cr_max = df[Y].max()
cr_max = 1500

linear_proxy = make_linear_proxy(df,X,Y)
linear_approx = make_approx_fidelity(linear_proxy,sd)
polynomial_proxy = make_polynomial_proxy(df,X,Y,deg)
polynomial_approx = make_approx_fidelity(polynomial_proxy,sd)
#objective_fx = on_error(linear_proxy, np.inf)
objective_fx = on_error(linear_approx, np.inf)
#objective_fx = on_error(polynomial_proxy, np.inf)
#objective_fx = on_error(linear_approx, np.inf)

for i in range(0,10):
    target = random.uniform(cr_min, cr_max)
    threshold = target * 0.05
    #print(f'target: {target}, threshold: {threshold}')
    objective = make_callback(objective_fx, target)
    
    print(f'BINARY SEARCH')
    start = time.perf_counter()
    result = binary_search(lower_bound,upper_bound,threshold,objective,max_iters,max_searches)
    stop = time.perf_counter()
    pred = objective.history[-1][1]
    lin_approx = linear_proxy(objective.history[-1][0])
    print(f'target: {target}, threshold: {threshold}')
    print(f'pred: {pred}, actual: {lin_approx}') 
    print(f'time: {stop - start}')
    objective.reset()
    
    poly_objective = make_polynomial_callback(objective_fx, target)
    x0 = orig_x.iloc[1]
    x1 = orig_x.iloc[-2]
    print(f'\nBRENTS METHOD')
    start = time.perf_counter()
    result = brents(poly_objective,x0,x1,max_searches)
    stop = time.perf_counter()
    pred = poly_objective.history[-1][1]
    lin_approx = linear_proxy(poly_objective.history[-1][0])
    #print(f'target: {target}') 
    print(f'target: {target}, threshold: {threshold}')
    print(f'pred: {pred}, actual: {lin_approx}') 
    print(f'time: {stop - start}')
    print(f'\n')
    poly_objective.reset()


