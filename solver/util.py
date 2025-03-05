import sys
import os
import re
from pathlib import Path
import glob
from scipy import stats
import pandas as pd
import cfg

################################################################################################################################
def get_results(fpath,fpattern):
    df = []
    files = glob.glob(os.path.join(fpath, f"{fpattern}*.csv"))
    for f in files:
        tmpdf = pd.read_csv(f,index_col=0)
        fname = Path(f.split("/")[-1]).stem
        errmode = fname.split('_')[-1]
        fname = fname.split('_')[-2]
        field,timestep = fname.split('f')
        
        tmpdf['field'] = field
        tmpdf['timestep'] = timestep
        tmpdf['errmode'] = errmode
        
        df.append(tmpdf)
        
    results_df = pd.concat(df,ignore_index=True)    
    return results_df
################################################################################################################################
def get_nearest_cr(df,target):
    closest = df.iloc[(df[cfg.Y] - target).abs().argsort()[:1]]
    closest = closest[[cfg.X,cfg.Y,cfg.Z]]
    #closest.columns = [X + '_closest', Y + '_closest', Z + '_closest']
    
    return list(closest.iloc[0])
################################################################################################################################