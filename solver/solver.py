#!/usr/bin/env python
import pandas as pd
import numpy as np
import time
from numpy.polynomial import Polynomial
from scipy.optimize import minimize
import matplotlib.pyplot as plt
import dlib
import random
import cfg
import util

################################################################################################################################
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
################################################################################################################################
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
################################################################################################################################
def make_inverted_objective(proxy):
    def inverted(x):
        return -proxy(x)
    return inverted
################################################################################################################################
def on_error(f, on_error):
    def g(*args):
        try:
            return f(*args)
        except:
            return on_error
    return g
################################################################################################################################
def make_acc_fidelity(proxy):
    def high(x: float) -> float:
        time.sleep(1000/1_000_000_000)
        return proxy(x)
    return high
################################################################################################################################
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
################################################################################################################################
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
################################################################################################################################
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
################################################################################################################################
def make_binary_search_dlib_callback(proxy,target):
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
        #print(f"Iteration {callback.iter}: Current eb = {x}, Pred CR = {y}, diff = {diff}, time = {end - start}")
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
################################################################################################################################    
def binary_search_dlib(low,high,objective,max_iters,max_searches,tolerance=1e-5):
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
        if x < mid:
            high = mid
        else:
            low = mid
        #if high - low < tolerance:
        #    break
    return closest_pred,closest_x    
################################################################################################################################
def make_binary_search_callback(proxy,target):

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
        #print(f"Iteration {callback.iter}: Current eb = {x}, Pred CR = {y}, diff = {diff}, time = {end - start}")
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
################################################################################################################################
def binary_search(low,high,objective,max_searches,tolerance=1e-5):
    iters = 0
    closest_pred = np.inf
    closest_x = 0
    while iters < max_searches:
        x = (high + low) / 2
        diff = objective(x)
        y = abs(diff)
        objective.reset_iter()
        if y < closest_pred:
            closest_pred = y
            closest_x = x
        if diff < 0:
            low = x
        elif diff > 0:
            high = x
        else: # diff == 0
            break
        iters = iters + 1
    return closest_pred,closest_x
################################################################################################################################
def run_binary_search(comp,errmode,max_searches,max_trials,cr_max):
    #sd = 5
    #deg = 7
    preds = []
    for field in cfg.fields:
        print(field)
        results_df = util.get_results(cfg.resultsdir, f'hurricane_{comp}_{field}f*{errmode}')
        results_df = results_df[results_df['size:compression_ratio'] <= cr_max]
        for t in range(1,49):
            ts = f'{t:02d}'
            df = results_df[results_df['timestep'] == ts]
            if len(df) == 0:
                continue

            max_cr = df[cfg.Y].max()
            min_cr = df[cfg.Y].min()

            linear_proxy = make_linear_proxy(df,cfg.X,cfg.Y)
            objective_fx = on_error(linear_proxy, np.inf)

            lower_bound = df[cfg.X].min()
            upper_bound = df[cfg.X].max()
            df = df.sort_values(cfg.X)

            orig_x = df[cfg.X]
            orig_y = df[cfg.Y]
            orig_z = df[cfg.Z]

            for trial in range(max_trials):

                target = random.uniform(min_cr, max_cr)
                closest_eb,closest_cr,closest_psnr = util.get_nearest_cr(df,target)

                for search in range(2,max_searches+1):

                    threshold = target * 0.05
                    objective = make_binary_search_callback(objective_fx, target)

                    start = time.perf_counter()
                    #result = binary_search_dlib(lower_bound,upper_bound,objective,max_iters,search)
                    result = binary_search(lower_bound,upper_bound,objective,search)
                    stop = time.perf_counter()
                    pred = objective.history[-1][1]
                    pred_eb = objective.history[-1][0]
                    lin_approx = linear_proxy(objective.history[-1][0])

                    preds.append([comp,errmode, field,ts,'binary search','linear','no',search,
                                  0,target,pred,pred_eb,closest_cr,closest_eb,closest_psnr
                    ])

                    objective.reset()

    predictions = pd.DataFrame(preds)
    # sampling column indicates whether or not we 'ran the full compressor' (aka did an accurate
    # linear interpretation) or if we added noise to assume a less accurate method
    # proxy column indicates a linear or polynomial proxy 
    predictions.columns=['comp','error_mode', 'field','ts','search method','proxy','sampling','searches',
                         'dlib_iters', 'target_cr','pred_cr', 'pred_eb','closest_cr','closest_eb','closest_psnr']
    outfile = 'predictions_' + comp + '_' + errmode + '_hurricane_binary_search_linear.csv'
    predictions.to_csv(outfile)
    return predictions
