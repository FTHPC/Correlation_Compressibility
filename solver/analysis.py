import pandas as pd
import numpy as np
import time
from numpy.polynomial import Polynomial
from scipy.optimize import minimize
from sklearn.metrics import r2_score
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

    df['abs_err'] = abs(df['closest_cr'] - df['pred_cr'])
    df['APE'] = (df['abs_err'] / df['closest_cr']) * 100
    
    errors = df.groupby(['searches']).agg(
        mean_abserr=('abs_err', 'mean'),
        mean_APE=('APE', 'mean'),
        MAPE=('APE','median'),
        sem_abserr=('APE', sem_custom)
    ).reset_index()
    #errors['MAPE'] = errors['MAPE'] * 100
    
    return errors
################################################################################################################################
def calculate_error_by_field(df):
    def sem_custom(x):
        return stats.sem(x, ddof=0)

    df['abs_err'] = abs(df['closest_cr'] - df['pred_cr'])
    df['APE'] = abs((df['closest_cr'] - df['pred_cr']) / df['closest_cr']) * 100
    
    errors = df.groupby(['searches','field']).agg(
        mean_abserr=('abs_err', 'mean'),
        mean_APE=('APE','mean'),
        MAPE=('APE','median'),
        sem_abserr=('APE', sem_custom)
    ).reset_index()
    #errors['MAPE'] = errors['MAPE'] * 100
    
    return errors



################################################################################################################################
def calculate_error_by_field_withr2(df):
    def sem_custom(x):
        return stats.sem(x, ddof=0)

    def calculate_metrics(df):
        return pd.Series({
            'mean_abserr': df['abs_err'].mean(),
            'mean_APE': df['APE'].mean(),
            'MAPE': df['APE'].median(),
            'stdv': np.std(df['APE']),
            'sem_abserr': sem_custom(df['APE']),
            'R_squared': r2_score(df['closest_cr'], df['pred_cr'])
        })

    df['abs_err'] = abs(df['closest_cr'] - df['pred_cr'])
    df['APE'] = abs((df['closest_cr'] - df['pred_cr']) / df['closest_cr']) * 100
    errors = df.groupby(['search method', 'searches', 'field']).apply(calculate_metrics).reset_index()
    errors['dlib_iters'] = 0
    #errors = df.groupby(['search method', 'searches', 'dlib_iters', 'field']).apply(calculate_metrics).reset_index() 
    errors = errors[['search method', 'searches', 'dlib_iters', 'field', 'mean_abserr', 'mean_APE', 'MAPE','stdv', 'sem_abserr', 'R_squared']]
    return errors
################################################################################################################################
def calculate_error_by_field_withr2_poly(df):
    def sem_custom(x):
        return stats.sem(x, ddof=0)

    def calculate_metrics(df):
        return pd.Series({
            'mean_abserr': df['abs_err'].mean(),
            'mean_APE': df['APE'].mean(),
            'MAPE': df['APE'].median(),
            'stdv': np.std(df['APE']),
            'sem_abserr': sem_custom(df['APE']),
            'R_squared': r2_score(df['closest_cr'], df['pred_cr'])
        })

    df['abs_err'] = abs(df['closest_cr'] - df['pred_cr'])
    df['APE'] = abs((df['closest_cr'] - df['pred_cr']) / df['closest_cr']) * 100
    errors = df.groupby(['search method', 'degree', 'dlib_iters', 'field']).apply(calculate_metrics).reset_index()    
    
    return errors

################################################################################################################################
def calculate_error_by_field_withr2_dlib(df):
    def sem_custom(x):
        return stats.sem(x, ddof=0)

    def calculate_metrics(df):
        return pd.Series({
            'mean_abserr': df['abs_err'].mean(),
            'mean_APE': df['APE'].mean(),
            'MAPE': df['APE'].median(),
            'stdv': np.std(df['APE']),
            'sem_abserr': sem_custom(df['APE']),
            'R_squared': r2_score(df['closest_cr'], df['pred_cr'])
        })

    df.replace([np.inf], np.nan, inplace=True)
    df.dropna(inplace=True)
    df['abs_err'] = abs(df['closest_cr'] - df['pred_cr'])
    df['APE'] = abs((df['closest_cr'] - df['pred_cr']) / df['closest_cr']) * 100
    errors = df.groupby(['search method', 'searches','dlib_iters','field']).apply(calculate_metrics).reset_index()
    
    return errors
################################################################################################################################

