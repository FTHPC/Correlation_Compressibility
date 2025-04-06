import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sys
from pathlib import Path
import os
from scipy import stats
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.animation as animation
import seaborn as sns
from  matplotlib.colors import LinearSegmentedColormap

import cfg
import util
import analysis as an

################################################################################################################################
def create_raw_cr_figs_by_field_and_timestep(comp,errmode,field,timestep,cr_max,app='hurricane'):
    
    compname = comp.upper()
    timestep = f"{timestep:02d}"
    with PdfPages(f'img/raw_crs/{app}_{comp}_{field}_{timestep}_{errmode}_max_{cr_max}.pdf') as pdf_pages:
        fpattern = app + '_' + comp + '_' + field
        if app == 'hurricane':
            fpattern = fpattern + 'f'
        fpattern = fpattern + '*' + errmode        
        results_df = util.get_result_file(cfg.resultsdir, fpattern)
        df = results_df[results_df['size:compression_ratio'] <= cr_max]

        #for t in range(1,49):

        #df = results_df[results_df['timestep'] == timestep]
        #if len(df) == 0:
        #    continue

        df = df.sort_values(cfg.X)

        x = df[cfg.X]
        if errmode == 'rel':
            x = x * df['error_stat:value_range']
        y = df[cfg.Y]
        z = df[cfg.Z]

        fig, ax1 = plt.subplots()

        ax1.plot(x, z, color='blue',label='PSNR')
        ax1.set_xlabel('Error Bound')
        ax1.set_ylabel('PSNR',color='black')
        ax1.tick_params(axis='y',labelcolor='black')

        ax2 = ax1.twinx()
        ax2.plot(x, y, color='red',label='Compression Ratio')
        ax2.set_ylabel('Compression Ratio',rotation=270,labelpad=15)
        ax2.tick_params(axis='y',labelcolor='black')
        #ax2.tick_params(axis='y', which='major', pad=15)

        lines1, labels1 = ax1.get_legend_handles_labels()
        lines2, labels2 = ax2.get_legend_handles_labels()
        ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left')
        plt.title(f'{field} {timestep} {compname} pressio:{errmode}')
        pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
        plt.close(fig)
        
################################################################################################################################
def create_raw_cr_figs(comp,errmode,cr_max,app='hurricane'):
    
    compname = comp.upper()
    #for field in cfg.fields:
    for field in cfg.get_fields(app):
        with PdfPages(f'img/raw_crs/{app}_{comp}_{field}_{errmode}_max_{cr_max}.pdf') as pdf_pages:
            fpattern = app + '_' + comp + '_' + field
            if app == 'hurricane':
                fpattern = fpattern + 'f'
            fpattern = fpattern + '*' + errmode
            #results_df = util.get_results(cfg.resultsdir, f'{app}_{comp}_{field}f*{errmode}',app)
            results_df = util.get_results(cfg.resultsdir, fpattern, app)
            results_df = results_df[results_df['size:compression_ratio'] <= cr_max]
            
            #for t in range(1,49):
            for t in cfg.get_timesteps(app):
                timestep = f"{t:02d}"
                df = results_df[results_df['timestep'] == timestep]
                if len(df) == 0:
                    continue

                df = df.sort_values(cfg.X)

                x = df[cfg.X]
                if errmode == 'rel':
                    x = x * df['error_stat:value_range']
                y = df[cfg.Y]
                z = df[cfg.Z]
                
                fig, ax1 = plt.subplots()

                ax1.plot(x, z, color='blue',label='PSNR')
                ax1.set_xlabel('Error Bound')
                ax1.set_ylabel('PSNR',color='black')
                ax1.tick_params(axis='y',labelcolor='black')

                ax2 = ax1.twinx()
                ax2.plot(x, y, color='red',label='Compression Ratio')
                ax2.set_ylabel('Compression Ratio',rotation=270)
                ax2.tick_params(axis='y',labelcolor='black')

                lines1, labels1 = ax1.get_legend_handles_labels()
                lines2, labels2 = ax2.get_legend_handles_labels()
                ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left')
                plt.title(f'{field} {timestep} {compname} pressio:{errmode}')
                pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
                plt.close(fig)
                
################################################################################################################################
def make_raw_figs_by_timestep():
    cr_max = 1500

    for field in list(results_df['field'].unique()):
        df = results_df[results_df['field'] == field]
        lower_bound = df[X].min()
        upper_bound = df[X].max()
        df = df.sort_values(X)

        orig_x = df[X]
        orig_y = df[Y]
        orig_z = df[Z]

        x0 = df.sample(n=1)[X].item()
        cr_min = df[Y].min()
        #cr_max = df[Y].max()

        fig, ax1 = plt.subplots()

        ax1.plot(orig_x, orig_z, color='blue')
        ax1.set_xlabel('Error Bound')
        ax1.set_ylabel('PSNR')
        ax1.tick_params(axis='y')

        ax2 = ax1.twinx()
        ax2.plot(orig_x, orig_y, color='red')
        ax2.set_ylabel('Compression Ratio')
        ax2.tick_params(axis='y')

        lines1, labels1 = ax1.get_legend_handles_labels()
        lines2, labels2 = ax2.get_legend_handles_labels()
        ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left')
        title_str = field
        plt.title(field)
        plt.show()            
    
################################################################################################################################
def create_raw_cr_figs_abs_and_rel(comp,cr_max,app='hurricane'):
    
    compname = comp.upper()
    for field in cfg.fields:
        with PdfPages(f'img/raw_crs/{app}_{comp}_{field}_both-ebm_max_{cr_max}.pdf') as pdf_pages:
            results1 = util.get_results(cfg.resultsdir, f'hurricane_{comp}_{field}f*abs', app)
            results2 = util.get_results(cfg.resultsdir, f'hurricane_{comp}_{field}f*rel', app)
            
            results1 = results1[results1['size:compression_ratio'] <= cr_max]
            results2 = results2[results2['size:compression_ratio'] <= cr_max]            
            
            for t in range(1,49):
                timestep = f"{t:02d}"
                df1 = results1[results1['timestep'] == timestep]
                df2 = results2[results2['timestep'] == timestep]
                if len(df1) == 0 or len(df2) == 0:
                    continue

                df1 = df1.sort_values(cfg.X)
                df2 = df2.sort_values(cfg.X)

                x1 = df1[cfg.X]
                y1 = df1[cfg.Y]
                z1 = df1[cfg.Z]
                
                x2 = df2[cfg.X]
                x2 = x2 * df2['error_stat:value_range']
                y2 = df2[cfg.Y]
                z2 = df2[cfg.Z]

                fig, (ax1,ax2) = plt.subplots(1,2,figsize=(12,5))
                ######################################################################
                ax1.plot(x1, z1, color='blue',label='PSNR')
                ax1.set_xlabel('Error Bound')
                ax1.set_ylabel('PSNR',color='black')
                ax1.tick_params(axis='y',labelcolor='black')

                ax1_secondary = ax1.twinx()
                ax1_secondary.plot(x1, y1, color='red',label='Compression Ratio')
                ax1_secondary.set_ylabel('Compression Ratio',color='black',rotation=180)
                ax1_secondary.tick_params(axis='y',labelcolor='black')
                
                ax1.set_title('pressio:abs')

                lines1, labels1 = ax1.get_legend_handles_labels()
                lines2, labels2 = ax1_secondary.get_legend_handles_labels()
                ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left')                
                ######################################################################
                ax2.plot(x2, z2, color='blue',label='PSNR')
                ax2.set_xlabel('Error Bound')
                ax2.set_ylabel('PSNR',color='black')
                ax2.tick_params(axis='y',labelcolor='black')

                ax2_secondary = ax2.twinx()
                ax2_secondary.plot(x2, y2, color='red',label='Compression Ratio')
                ax2_secondary.set_ylabel('Compression Ratio',color='black',rotation=180)
                ax2_secondary.tick_params(axis='y',labelcolor='black')
                
                ax2.set_title('pressio:rel')

                lines3, labels3 = ax2.get_legend_handles_labels()
                lines4, labels4 = ax2_secondary.get_legend_handles_labels()
                ax2.legend(lines3 + lines4, labels3 + labels4, loc='upper left')                                   
                ######################################################################
                fig.suptitle(f'{field} {timestep} {compname}',y=1.05)
                plt.tight_layout()
                pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
                plt.close(fig)                

################################################################################################################################
def make_error_barplot(errors,comp,):
    plt.bar(errors['searches'],errors['mean_APE'], yerr=errors['sem_abserr'],capsize=5)
    plt.title(f'{comp} pressio:{errmode}')
################################################################################################################################
def make_abs_error_barplot_by_searches_and_field(errors,comp,errmode,xmain,xsub,dlib=0,poly=0,rand=0,ylim=0,app='hurricane'):
    if xmain == 'searches':
        xlab = 'Searches'
        sort = 'Field'
        title_sub = '# Searches'
    elif xmain == 'degree':
        xlab = 'Degree'
        sort = 'Field'
        title_sub = 'Degree'
    else:
        xlab = 'Field'
        if xsub == 'searches':
            sort = 'Searches'
            title_sub = '# Searches'
        else:
            sort = 'Degree'
            title_sub = 'Degree'
    
    bar_width = 0.015
    compname = comp.upper()    
    ofile = 'img/results/accuracy/' + app + '_abserr_' + comp + '_' + errmode + '_combined_by-' + xmain 
    title = compname + ' ' + 'pressio:' + errmode + ' Median Absolute Error By ' + title_sub + ' and Field'
    legend_title = '# binary searches'
    if dlib:
        ofile = ofile + '_dlib'
        title = title + ' with dlib'
    if poly:
        ofile = ofile + '_poly'
        title = title + ' with Polynomial Estimation'
        legend_title = 'degree'
    if rand:
        ofile = ofile + '_rand'
        title = title + ' - random sampling'
    ofile = ofile + '.pdf'
    with PdfPages(ofile) as pdf_pages:    
        fig,ax = plt.subplots(figsize=(16,6))        
        
        x = np.arange(len(errors[xmain].unique()))
        
        spacing = .15
        x = x * spacing
        
        for i, xs in enumerate(errors[xsub].unique()):
            field_data = errors[errors[xsub] == xs]
            bars = ax.bar(x + i * bar_width, field_data['MAPE'], width=bar_width, label=xs)#, yerr=field_data['sem_abserr'],capsize=4.5)
            for bar in bars:
                height = bar.get_height()
                #ax.text(bar.get_x() + bar.get_width() / 2, height, f'{height:.1f}', ha='center', va='bottom')
        
        ax.set_xlabel(xlab)
        if ylim:
            ax.set_ylim(0,ylim)
        ax.set_ylabel('Median Absolute % Error')
        ax.set_xticks(x + (len(errors[xsub].unique()) - 1) * bar_width / 2, errors[xmain].unique())
        ax.set_xticklabels(errors[xmain].unique())
        plt.title(title)
        ax.legend(title=legend_title)
        pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
        plt.close(fig)

################################################################################################################################

def make_heatmap(comp,errmode,app='hurricane',noise=0):
    data = []

    b = util.get_binary_predictions(comp,errmode)
    bin_preds = an.calculate_error_by_field_withr2(b)
    dl = util.get_dlib_predictions(comp,errmode)
    dl_preds = an.calculate_error_by_field_withr2_dlib(dl)
    
    data = pd.concat([bin_preds,dl_preds],ignore_index=True)
    data = data.sort_values(by=['searches','dlib_iters'], ascending=[True,True])

    compname = comp.upper()  
    
    ofile = 'img/results/accuracy/' + app + '_' + comp + '_' + errmode + '_heatmap'
    if noise:
        ofile = ofile + '_noisy'
    ofile = ofile + '.pdf'
        
    cmap=LinearSegmentedColormap.from_list('rg',["g", "r"], N=256)
    
    with PdfPages(ofile) as pdf_pages:
        for field in data['field'].unique():            
            title = field + " " + compname + ' ' + 'pressio:' + errmode + ' MAPE: bin_search vs dlib'
            
            df = data[data['field'] == field]            
            df.set_index(['searches','dlib_iters'],append=True)
            df = df.pivot(index='searches',columns='dlib_iters',values='MAPE')
            
            fig, ax = plt.subplots()
            
            ax = sns.heatmap(df,cmap=cmap,annot=True)
            ax.invert_yaxis()
            #im = ax.imshow(df['MAPE'])            
            #ax.set_xticks(range(len(df['dlib_iters'])), labels=df['dlib_iters'])#,ha='right', rotation_mode='anchor')
            #ax.set_yticks(range(len(df['searches'])), labels=df['searches'])            
            ax.set_ylabel('# bin search')
            ax.set_xlabel('# dlib')
            plt.title(title)
            
            plt.tight_layout()
            pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
            plt.close(fig)  


################################################################################################################################
def create_raw_cr_figs_against_binary_predictions(comp,errmode,cr_max=1000,app='hurricane'):
    
    compname = comp.upper()
    b = util.get_binary_predictions(comp,errmode)
    #for field in cfg.fields:
    for field in cfg.get_fields(app):
        with PdfPages(f'img/results/accuracy/{app}_{comp}_{field}_{errmode}_max_{cr_max}.pdf') as pdf_pages:
            fpattern = app + '_' + comp + '_' + field
            if app == 'hurricane':
                fpattern = fpattern + 'f'
            fpattern = fpattern + '*' + errmode
            results_df = util.get_results(cfg.resultsdir, fpattern, app)
            results_df = results_df[results_df['size:compression_ratio'] <= cr_max]
            b_sub = b[b['field'] == field]
            
            #for t in range(1,49):
            for t in cfg.get_timesteps(app):
                timestep = f"{t:02d}"
                df = results_df[results_df['timestep'] == timestep]
                bf = b_sub[b_sub['ts'] == timestep]
                if len(df) == 0:
                    continue

                df = df.sort_values(cfg.X)

                x = df[cfg.X]
                if errmode == 'rel':
                    x = x * df['error_stat:value_range']
                y = df[cfg.Y]
                z = df[cfg.Z]
                
                fig, ax1 = plt.subplots()

                ax1.plot(x, z, color='blue',label='PSNR')
                ax1.set_xlabel('Error Bound')
                ax1.set_ylabel('PSNR',color='black')
                ax1.tick_params(axis='y',labelcolor='black')

                ax2 = ax1.twinx()
                ax2.plot(x, y, color='red',label='Compression Ratio')
                ax2.set_ylabel('Compression Ratio',rotation=270)
                ax2.tick_params(axis='y',labelcolor='black')

                lines1, labels1 = ax1.get_legend_handles_labels()
                lines2, labels2 = ax2.get_legend_handles_labels()
                ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left')
                plt.title(f'{field} {timestep} {compname} pressio:{errmode}')
                pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
                plt.close(fig)
                                









