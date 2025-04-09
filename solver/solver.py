#!/usr/bin/env python
import pandas as pd
import numpy as np
import time
from numpy.polynomial import Polynomial
from scipy.optimize import minimize
from scipy.optimize import minimize_scalar
import matplotlib.pyplot as plt
import dlib
import random
import cfg
import util
from ctypes import CDLL

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
def make_noisy_fidelity(proxy,scale):
    noise_db = {}
    def low(x: float) -> float:
        nonlocal noise_db
        if x not in noise_db:
            noise = np.random.normal(loc=scale)
            noise = noise * random.choice([-1,1])
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
def make_binary_search_callback(proxy,target):

    def callback(x):
        start = time.perf_counter()
        y = proxy(x)
        end = time.perf_counter()
        callback.iter = callback.iter + 1
        callback.history.append((x, y))
        callback.timing.append((end - start))
        diff = y - target
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
    return low,high
################################################################################################################################
def run_binary_search(comp,errmode,max_searches,max_trials,cr_max,noise,app='hurricane'):

    preds = []
    for field in cfg.get_fields(app):
        print(field)
        results_df = util.get_results(cfg.resultsdir, f'{app}_{comp}_{field}f*{errmode}')
        results_df = results_df[results_df[cfg.Y] <= cr_max]
        for t in cfg.get_timesteps(app):
            ts = f'{t:02d}'
            df = results_df[results_df['timestep'] == ts]
            if len(df) == 0:
                continue

            max_cr = df[cfg.Y].max()
            min_cr = df[cfg.Y].min()

            linear_proxy = make_linear_proxy(df,cfg.X,cfg.Y)
            
            if noise:
                cr_range = max_cr - min_cr
                scale = cr_range * noise
                linear_proxy = make_noisy_fidelity(linear_proxy, scale)
            else:
                scale = 0

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
                    
                    result = binary_search(lower_bound,upper_bound,objective,search)                    
                    pred = objective.history[-1][1]
                    pred_eb = objective.history[-1][0]
                    lin_approx = linear_proxy(objective.history[-1][0])

                    preds.append([comp,
                                  errmode, 
                                  field,ts,
                                  'binary search',
                                  'linear',
                                  scale,
                                  search,
                                  0,
                                  target,
                                  pred,
                                  pred_eb,
                                  closest_cr,
                                  closest_eb,
                                  closest_psnr
                    ])

                    objective.reset()

    predictions = pd.DataFrame(preds)

    predictions.columns=['comp',
                         'error_mode', 
                         'field','ts',
                         'search method',
                         'proxy',
                         'sampling',
                         'searches',
                         'dlib_iters',
                         'target_cr',
                         'pred_cr',
                         'pred_eb',
                         'closest_cr',
                         'closest_eb',
                         'closest_psnr'
                        ]
    outfile = 'predictions/predictions_' + comp + '_' + errmode + '_s-' + str(max_searches) + '_d-0_cr-' + str(cr_max) + app + '_' + app + '_binary_search_linear'
    if noise:
        outfile = outfile + '_' + str(noise) + '-noisy'
    outfile = outfile + '.csv'
    predictions.to_csv(outfile)
    return predictions


################################################################################################################################
def make_binary_search_dlib_callback(proxy,target):
    def callback(x):
        start = time.perf_counter()
        y = proxy(x)
        end = time.perf_counter()
        callback.iter = callback.iter + 1
        callback.history.append((x, y))
        callback.timing.append((end - start))
        diff = y - target
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

    def compare(b,d):
        ret = None
        bdiff = abs(b - target)
        ddiff = abs(d - target)
        if bdiff > ddiff:
            ret = 'dlib'
        else:
            ret = 'binary'
        return ret
            
    
    callback.reset = reset
    callback.reset_iter = reset_iter
    callback.timing = []
    callback.history = []
    callback.compare = compare
    callback.diffs = []
    callback.iter = 0
    return callback

################################################################################################################################  
def binary_search_dlib(low,high,b_objective,d_objective,max_iters,max_searches,tolerance=1e-5):
    libc = CDLL('libc.so.6')
    iters = 0
    closest_pred = np.inf
    closest_x = 0
    
    dlow,dhigh = binary_search(low,high,b_objective,max_searches)
    b_pred = b_objective.history[-1][1]
    b_pred_eb = b_objective.history[-1][0]    
    
    libc.srand(42)
    result = dlib.find_min_global(
            d_objective,
            [dlow], [dhigh],
            max_iters
    )
    d_pred = d_objective.history[-1][1]
    d_pred_eb = d_objective.history[-1][0]
    best = d_objective.compare(b_pred,d_pred)
    return best,dlow,dhigh

################################################################################################################################
def run_binary_search_dlib(comp,errmode,max_searches,dlib_iter,max_trials,cr_max,noise=1,app='hurricane'):    
    preds = []
    for field in cfg.get_fields(app):
        print(field)
        results_df = util.get_results(cfg.resultsdir, f'{app}_{comp}_{field}f*{errmode}')
        results_df = results_df[results_df[cfg.Y] <= cr_max]
        for t in cfg.get_timesteps(app):
            ts = f'{t:02d}'
            df = results_df[results_df['timestep'] == ts]
            if len(df) == 0:
                continue

            max_cr = df[cfg.Y].max()
            min_cr = df[cfg.Y].min()

            linear_proxy = make_linear_proxy(df,cfg.X,cfg.Y)
            if noise:
                cr_range = max_cr - min_cr
                scale = cr_range * noise                
                linear_proxy = make_noisy_fidelity(linear_proxy, scale)
            else:
                scale = 0
            objective_fx = on_error(linear_proxy, np.inf)

            lower_bound = df[cfg.X].min()
            upper_bound = df[cfg.X].max()
            df = df.sort_values(cfg.X)

            orig_x = df[cfg.X]
            orig_y = df[cfg.Y]
            orig_z = df[cfg.Z]

            for trial in range(max_trials):
                target = random.uniform(min_cr, max_cr)
                
                b_objective = make_binary_search_callback(objective_fx, target)                
                d_objective = make_binary_search_dlib_callback(objective_fx, target)
                
                closest_eb,closest_cr,closest_psnr = util.get_nearest_cr(df,target)

                for search in range(1,max_searches+1):                        
                    best,dlow,dhigh = binary_search_dlib(lower_bound,upper_bound,b_objective,d_objective,dlib_iter,search)

                    if best == 'dlib':
                        pred = d_objective.history[-1][1]
                        pred_eb = d_objective.history[-1][0]
                        worse_pred = b_objective.history[-1][1]
                        worse_pred_eb = b_objective.history[-1][0]
                    else:
                        pred = b_objective.history[-1][1]
                        pred_eb = b_objective.history[-1][0]
                        worse_pred = d_objective.history[-1][1]
                        worse_pred_eb = d_objective.history[-1][0]                        
                    
                    #lin_approx = linear_proxy(objective.history[-1][0])

                    preds.append([comp,
                                  errmode, 
                                  field,ts,
                                  'binary search dlib',
                                  'linear',
                                  scale,
                                  search,
                                  dlib_iter,
                                  target,
                                  pred,
                                  pred_eb,
                                  closest_cr,
                                  closest_eb,
                                  closest_psnr,
                                  best,
                                  dlow,
                                  dhigh,
                                  worse_pred,
                                  worse_pred_eb
                    ])
                    b_objective.reset()
                    d_objective.reset()

    predictions = pd.DataFrame(preds)

    predictions.columns=['comp','error_mode', 'field','ts','search method','proxy','sampling','searches',
                         'dlib_iters', 'target_cr','pred_cr', 'pred_eb','closest_cr','closest_eb','closest_psnr', 'best','dlow','dhigh','worse_pred','worse_eb']
    outfile = 'predictions/predictions_' + comp + '_' + errmode + '_s-' + str(max_searches) + '_d-'+str(dlib_iter) + '_cr-' + str(cr_max) + '_' + app + '_binary_search_dlib_linear'
    if noise:
        outfile = outfile + '_' + str(noise) + '-noisy'
    outfile = outfile + '.csv'
    predictions.to_csv(outfile)
    return predictions

################################################################################################################################
def run_search_dlib_only(comp,errmode,dlib_iters,max_trials,cr_max,noise=1,app='hurricane'):
    
    libc = CDLL('libc.so.6')
    preds = []
    for field in cfg.get_fields(app):
        print(field)
        results_df = util.get_results(cfg.resultsdir, f'{app}_{comp}_{field}f*{errmode}')
        results_df = results_df[results_df[cfg.Y] <= cr_max]
        for t in cfg.get_timesteps(app):
            ts = f'{t:02d}'
            df = results_df[results_df['timestep'] == ts]
            if len(df) == 0:
                continue

            max_cr = df[cfg.Y].max()
            min_cr = df[cfg.Y].min()

            linear_proxy = make_linear_proxy(df,cfg.X,cfg.Y)
            if noise:
                #scale = np.std(df[cfg.Y])
                cr_range = max_cr - min_cr
                scale = cr_range * noise                
                #linear_proxy = make_approx_fidelity(linear_proxy, scale)
                linear_proxy = make_noisy_fidelity(linear_proxy, scale)
            else:
                scale = 0
            objective_fx = on_error(linear_proxy, np.inf)

            lower_bound = df[cfg.X].min()
            upper_bound = df[cfg.X].max()
            df = df.sort_values(cfg.X)

            orig_x = df[cfg.X]
            orig_y = df[cfg.Y]
            orig_z = df[cfg.Z]

            for trial in range(max_trials):

                target = random.uniform(min_cr, max_cr)
                objective = make_binary_search_dlib_callback(objective_fx, target)

                closest_eb,closest_cr,closest_psnr = util.get_nearest_cr(df,target)

                for dlib_iter in range(1,dlib_iters+1):
                    
                    libc.srand(42)
                    result = dlib.find_min_global(objective,[lower_bound],[upper_bound],dlib_iter)
                    x = result[0][0]
                    y = result[1]
                    #objective.reset_iter()
        
                    #diff = objective.diffs[-1]
                    #pred = y
                    #pred_eb = x
                    pred = objective.history[-1][1]
                    pred_eb = objective.history[-1][0]
                    #lin_approx = linear_proxy(x)

                    preds.append([comp,
                                  errmode, 
                                  field,ts,
                                  'dlib only',
                                  'linear',
                                  scale,
                                  1,
                                  dlib_iter,
                                  target,
                                  pred,
                                  pred_eb,
                                  closest_cr,
                                  closest_eb,
                                  closest_psnr
                    ])
                    objective.reset()

    predictions = pd.DataFrame(preds)
    # sampling column indicates whether or not we 'ran the full compressor' (aka did an accurate
    # linear interpretation) or if we added noise to assume a less accurate method
    # proxy column indicates a linear or polynomial proxy 
    predictions.columns=['comp','error_mode', 'field','ts','search method','proxy','sampling','searches',
                         'dlib_iters', 'target_cr','pred_cr', 'pred_eb','closest_cr','closest_eb','closest_psnr']
    #outfile = 'predictions_' + comp + '_' + errmode + '_s' + str(max_searches) + '_d' + str(max_dlib_iters) + '_cr' + str(cr_max) + '_hurricane_binary_search_dlib_linear'
    outfile = 'predictions/predictions_' + comp + '_' + errmode + '_s-1_d-'+str(dlib_iters) + '_cr-' + str(cr_max) + '_' + app + '_search_dlib_only'
    if noise:
        outfile = outfile + '_' + str(noise) + '-noisy'
    outfile = outfile + '.csv'
    predictions.to_csv(outfile)
    return predictions

################################################################################################################################
def make_polynomial_search_callback(proxy,target):
    def callback(x):
        y = proxy(x)
        callback.iter = callback.iter + 1
        callback.history.append((x, y))
        #print(f'y: {y} (y-target): {y - target}')
        callback.diffs.append((y - target)**2)
        diff = (y - target)**2
        #print(f"Iteration {callback.iter}: Current eb = {x}, Pred CR = {y}, diff = {diff}")
        return diff

    def reset():
        nonlocal callback
        callback.history = []
        callback.diffs = []
        callback.iter = 0
       
    def reset_iter():
        callback.iter = 0
    
    callback.reset = reset
    callback.reset_iter = reset_iter
    callback.history = []
    callback.diffs = []
    callback.iter = 0
    return callback


################################################################################################################################
def make_polynomial_proxy(low,high,objective,degree,rand):
    assert degree >= 1
    
    n = degree + 1    
    if(rand):
        xvals = np.random.uniform(low, high, n)
    else:
        xvals = np.linspace(low,high,num=n,endpoint=False)
    yvals = []    
    for x in xvals:
        yvals.append(objective(x))        
    poly = Polynomial.fit(xvals,yvals,degree).convert()
    #print(poly)
    
    return poly
################################################################################################################################
def run_polynomial_search(comp,errmode,max_degree,max_trials,cr_max,rand=0,noise=0,app='hurricane'):
    preds = []
    for field in cfg.get_fields(app):
        print(field)
        results_df = util.get_results(cfg.resultsdir, f'hurricane_{comp}_{field}f*{errmode}')
        results_df = results_df[results_df[cfg.Y] <= cr_max]
        for t in cfg.get_timesteps(app):
            ts = f'{t:02d}'
            df = results_df[results_df['timestep'] == ts]
            if len(df) == 0:
                continue
            #print(f"df[X][1]: {type(df[cfg.X][1])}, shape: {np.shape(df[cfg.X][1])}")
            max_cr = df[cfg.Y].max()
            min_cr = df[cfg.Y].min()

            linear_proxy = make_linear_proxy(df,cfg.X,cfg.Y)
            
            if noise:
                #scale = np.std(df[cfg.Y])
                cr_range = max_cr - min_cr
                scale = cr_range * noise                
                #linear_proxy = make_approx_fidelity(linear_proxy, scale)
                linear_proxy = make_noisy_fidelity(linear_proxy, scale)
            else:
                scale = 0

            objective_fx = on_error(linear_proxy, np.inf)
            
            df = df.sort_values(cfg.X)
            orig_x = df[cfg.X]
            orig_y = df[cfg.Y]
            orig_z = df[cfg.Z]
            
            #lower_bound = df[cfg.X].min()
            #print(orig_x[1])
            lower_bound = orig_x.iloc[1]
            upper_bound = df[cfg.X].max()

                
            for trial in range(max_trials):
                target = random.uniform(min_cr, max_cr)
                #print(target)
                closest_eb,closest_cr,closest_psnr = util.get_nearest_cr(df,target)
                
                for degree in range(1,max_degree):
                    
                    poly = make_polynomial_proxy(lower_bound,upper_bound,objective_fx,degree,rand)
                    objective = make_polynomial_search_callback(poly, target)
                    
                    result = minimize_scalar(objective, bounds=(lower_bound,upper_bound),method='bounded')
                    pred = objective.history[-1][1]
                    pred_eb = objective.history[-1][0]
                    #print(f'pred: {pred} pred_eb: {pred_eb}')
                    preds.append([comp,errmode,field,ts,
                                  'polynomial search', 'polynomial', 
                                  scale,degree,0,target,pred,pred_eb,
                                  closest_cr,closest_eb,closest_psnr
                    ])

                    objective.reset()

    predictions = pd.DataFrame(preds)
    predictions.columns=['comp',
                         'error_mode',
                         'field','ts',
                         'search method',
                         'proxy','sampling',
                         'degree',
                         'dlib_iters', 
                         'target_cr',
                         'pred_cr',
                         'pred_eb',
                         'closest_cr',
                         'closest_eb',
                         'closest_psnr']
    outfile = 'predictions/predictions_' + comp + '_' + errmode + '_s' + str(max_degree) + '_d0_cr' + str(cr_max) + '_' + app + '_polynomial_search'
    if rand:
        outfile = outfile + '_random'
    if noise:
        outfile = outfile + '_' + str(noise) + '-noisy'
    outfile = outfile + '.csv'
    predictions.to_csv(outfile)
    return predictions
