import pandas as pd
import numpy as np
import time
from numpy.polynomial import Polynomial
from scipy.optimize import minimize
import matplotlib.pyplot as plt
import dlib
import random
import sys
from pathlib import Path
import os
import re
import glob
import random
from scipy import stats
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import cfg

################################################################################################################################
def calculate_error(df):
    errors = []
    for search in df['searches'].unique():
        tmpdf = df[df['searches'] == search]

        actual,pred = np.array(tmpdf['target_cr']),np.array(tmpdf['pred_cr'])

        mean_err = abs(np.subtract(actual,pred).mean())
        stdv_err = stats.sem(np.subtract(actual,pred))
        #stdv_err = np.std(np.divide(abs(np.subtract(actual,pred)),actual))
        #stdv_err = np.std(np.subtract(actual,pred))
        mean_relerr = (np.divide(abs(np.subtract(actual,pred)),actual)).mean()

        root_mse = np.sqrt(np.square(np.subtract(actual,pred)).mean())
        errors.append([search,mean_err,stdv_err,mean_relerr,root_mse])
    
    error_df = pd.DataFrame(errors)
    #errors.append([search,root_mse,stdv_err])    
    error_df.columns=['searches','abs mean error','stdv','mean rel err','rmse']
    
    return error_df
################################################################################################################################
def calculate_error_by_searches(df):
    def sem_custom(x):
        return stats.sem(x, ddof=1)

    df['abs_err'] = abs(df['target_cr'] - df['pred_cr'])
    df['abs_rel_err'] = df['abs_err'] / df['target_cr']
    
    errors = df.groupby(['searches']).agg(
        mean_abserr=('abs_err', 'mean'),
        sem_abserr=('abs_rel_err', sem_custom),
        mean_relerr=('abs_rel_err','mean')
    ).reset_index()
    
    return errors
################################################################################################################################
def calculate_error_by_field(df):
    def sem_custom(x):
        return stats.sem(x, ddof=0)

    df['abs_err'] = abs(df['target_cr'] - df['pred_cr'])
    df['abs_rel_err'] = abs((df['target_cr'] - df['pred_cr']) / df['target_cr'])
    
    errors = df.groupby(['searches','field']).agg(
        mean_abserr=('abs_err', 'mean'),
        sem_abserr=('abs_rel_err', sem_custom),
        mean_relerr=('abs_rel_err','mean')
    ).reset_index()
    
    return errors
################################################################################################################################
