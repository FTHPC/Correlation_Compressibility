import sys
import os
import re
from pathlib import Path
import glob
from scipy import stats
import pandas as pd
import cfg

################################################################################################################################
def get_result_file(fpath,fpattern,app):
    df = []
    print(fpattern)
    path = os.path.join(fpath, f"{fpattern}.csv")
    print(path)
    #f = files[1]
    
    df = pd.read_csv(path,index_col=0)
    fname = Path(path.split("/")[-1]).stem
    errmode = fname.split('_')[-1]
     
    if app == 'hurricane':
        fname = fname.split('_')[-2]
        field,timestep = fname.split('f') 

    if app == 'NYX':
        timestep = '01'
        if len(fname.split('_')) == 4:
            field = fname.split('_')[-2]
        else:
            field = fname.split('_')[2] + '_' + fname.split('_')[3]     

    df['timestep'] = timestep
    df['field'] = field
    df['errmode'] = errmode    
    
    return df

################################################################################################################################
def get_results(fpath,fpattern,app='hurricane'):
    df = []
    #print(fpath)
    #print(fpattern)
    files = glob.glob(os.path.join(fpath, f"{fpattern}*.csv"))
    #print(files)
    for f in files:
        tmpdf = pd.read_csv(f,index_col=0)
        fname = Path(f.split("/")[-1]).stem
        errmode = fname.split('_')[-1]

        if app == 'hurricane':
            fname = fname.split('_')[-2]
            field,timestep = fname.split('f') 
        
        if app == 'NYX':
            timestep = '01'
            if len(fname.split('_')) == 4:
                field = fname.split('_')[-2]
            else:
                field = fname.split('_')[2] + '_' + fname.split('_')[3]     
        
        tmpdf['timestep'] = timestep
        tmpdf['field'] = field
        tmpdf['errmode'] = errmode
        
        df.append(tmpdf)
        
    results_df = pd.concat(df,ignore_index=True)    
    return results_df

################################################################################################################################
def get_predictions(fpath,fpattern,app='hurricane'):
    df = []
    files = glob.glob(os.path.join(fpath, f"{fpattern}*.csv"))
    for f in files:
        tmpdf = pd.read_csv(f,index_col=0)
        fname = Path(f.split("/")[-1]).stem
        errmode = fname.split('_')[-1]
        
        if app == 'hurricane':
            fname = fname.split('_')[-2]
            field,timestep = fname.split('f') 
        
        if app == 'NYX':
            timestep = '01'
            if len(fname.split('_')) == 4:
                field = fname.split('_')[-2]
            else:
                field = fname.split('_')[2] + '_' + fname.split('_')[3]          
        
        tmpdf['field'] = field
        tmpdf['timestep'] = timestep
        tmpdf['errmode'] = errmode
        
        df.append(tmpdf)
        
    results_df = pd.concat(df,ignore_index=True)    
    return results_df
################################################################################################################################
def get_dlib_predictions(comp,errmode,app='hurricane'):
    fpath = 'predictions/dlib/'
    df = []
    files = glob.glob(os.path.join(fpath, f"*{comp}_{errmode}*{app}*.csv"))
    for f in files:
        tmpdf = pd.read_csv(f,index_col=0)
        if 'dlib only' in list(tmpdf['search method']):
            tmpdf['searches'] = 0
        df.append(tmpdf)
        
    predictions = pd.concat(df,ignore_index=True)    
    return predictions
################################################################################################################################
def get_poly_predictions(comp,errmode,app='hurricane',rand=0):
    fpath = 'predictions/polynomial/'
    files = glob.glob(os.path.join(fpath, f"*{comp}_{errmode}*{app}*.csv"))
    #print(files)
    if rand:
        files = [f for f in files if 'random' in f]
    else:
        files = [f for f in files if 'random' not in f]
    df = []
    for f in files:
        tmpdf = pd.read_csv(f,index_col=0)
        tmpdf['searches'] = 0
        df.append(tmpdf)
        
    predictions = pd.concat(df,ignore_index=True)    
    return predictions

################################################################################################################################
def get_binary_predictions(comp,errmode,app='hurricane'):
    fpath = 'predictions/binary/'
    df = []
    files = glob.glob(os.path.join(fpath, f"*{comp}_{errmode}*{app}*.csv"))
    for f in files:
        tmpdf = pd.read_csv(f,index_col=0)        
        df.append(tmpdf)
        
    predictions = pd.concat(df,ignore_index=True)
    predictions['dlib_iters'] = 0
    return predictions
################################################################################################################################
def get_noisy_dlib_predictions(comp,errmode,app='hurricane'):
    fpath = 'predictions/noise/dlib/'
    df = []
    files = glob.glob(os.path.join(fpath, f"*{comp}_{errmode}*{app}*.csv"))
    for f in files:
        tmpdf = pd.read_csv(f,index_col=0)
        if 'dlib only' in list(tmpdf['search method']):
            tmpdf['searches'] = 0
        err = Path(f.split('/')[-1]).stem
        err = Path(err.split('.')[-1]).stem
        err = Path(err.split('-')[0]).stem
        if err == '01': noise = .01
        if err == '05': noise = .05
        if err == '1': noise = .1
        if err == '2': noise = .2
        tmpdf['noise'] = noise
        
        df.append(tmpdf)
        
    predictions = pd.concat(df,ignore_index=True)    
    return predictions
################################################################################################################################
def get_noisy_poly_predictions(comp,errmode,app='hurricane'):
    fpath = 'predictions/noise/polynomial/'
    df = []
    files = glob.glob(os.path.join(fpath, f"*{comp}_{errmode}*{app}*.csv"))
    for f in files:
        tmpdf = pd.read_csv(f,index_col=0)
        tmpdf['searches'] = 0
        tmpdf['dlib_iters'] == 0
        err = Path(f.split('/')[-1]).stem
        err = Path(err.split('.')[-1]).stem
        err = Path(err.split('-')[0]).stem
        if err == '01': noise = .01
        if err == '05': noise = .05
        if err == '1': noise = .1
        if err == '2': noise = .2
        tmpdf['noise'] = noise
        
        df.append(tmpdf)
        
    predictions = pd.concat(df,ignore_index=True)    
    return predictions

################################################################################################################################
def get_noisy_binary_predictions(comp,errmode,app='hurricane'):
    fpath = 'predictions/noise/binary/'
    df = []
    files = glob.glob(os.path.join(fpath, f"*{comp}_{errmode}*{app}*.csv"))
    for f in files:
        tmpdf = pd.read_csv(f,index_col=0)
        err = Path(f.split('/')[-1]).stem
        err = Path(err.split('.')[-1]).stem
        err = Path(err.split('-')[0]).stem
        if err == '01': noise = .01
        if err == '05': noise = .05
        if err == '1': noise = .1
        if err == '2': noise = .2
        tmpdf['noise'] = noise
        df.append(tmpdf)
        
    predictions = pd.concat(df,ignore_index=True)
    predictions['dlib_iters'] = 0
    return predictions

                              
################################################################################################################################

def get_nearest_cr(df,target):
    closest = df.iloc[(df[cfg.Y] - target).abs().argsort()[:1]]
    closest = closest[[cfg.X,cfg.Y,cfg.Z]]
    #closest.columns = [X + '_closest', Y + '_closest', Z + '_closest']
    
    return list(closest.iloc[0])
################################################################################################################################