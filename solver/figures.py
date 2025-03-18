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
import cfg
import util


################################################################################################################################
def create_raw_cr_figs(comp,errmode,cr_max):
    
    compname = comp.upper()
    for field in cfg.fields:
        with PdfPages(f'img/raw_crs/hurricane_{comp}_{field}_{errmode}_max_{cr_max}.pdf') as pdf_pages:
            results_df = util.get_results(cfg.resultsdir, f'hurricane_{comp}_{field}f*{errmode}')
            results_df = results_df[results_df['size:compression_ratio'] <= cr_max]
            
            for t in range(1,49):
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
    sd = 5
    deg = 7
    max_iters = 10# 30
    max_searches = 5#10

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
def create_raw_cr_figs_abs_and_rel(comp,cr_max):
    
    compname = comp.upper()
    for field in cfg.fields:
        with PdfPages(f'img/raw_crs/hurricane_{comp}_{field}_both-ebm_max_{cr_max}.pdf') as pdf_pages:
            results1 = util.get_results(cfg.resultsdir, f'hurricane_{comp}_{field}f*abs')
            results2 = util.get_results(cfg.resultsdir, f'hurricane_{comp}_{field}f*rel')
            
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
    plt.bar(errors['searches'],errors['mean_abserr'], yerr=errors['sem_abserr'],capsize=5)
    plt.title(f'{comp} pressio:{errmode}')
    

################################################################################################################################
def make_abs_error_barplot_by_searches_and_field(errors,comp,errmode,xmain,xsub,dlib=0):
    if xmain == 'searches':
        xlab = 'Searches'
        sort = 'Field'
    else:
        xlab = 'Field'
        sort = 'Searches' 
    
    bar_width = 0.03
    compname = comp.upper()    
    ofile = 'img/results/accuracy/hurricane_abserr_' + comp + '_' + errmode + '_combined_by-' + xmain 
    title = compname + ' ' + 'pressio:' + errmode + ' Mean Absolute Error By # Searches and Field'
    if dlib:
        ofile = ofile + '_dlib'
        title = title + ' with dlib'
    ofile = ofile + '.pdf'
    with PdfPages(ofile) as pdf_pages:    
        fig,ax = plt.subplots(figsize=(12,6))        
        
        x = np.arange(len(errors[xmain].unique()))
        
        spacing = .35
        x = x * spacing
        
        for i, xs in enumerate(errors[xsub].unique()):
            field_data = errors[errors[xsub] == xs]
            bars = ax.bar(x + i * bar_width, field_data['mean_abserr'], width=bar_width, label=xs, yerr=field_data['sem_abserr'],capsize=4.5)
            for bar in bars:
                height = bar.get_height()
                #ax.text(bar.get_x() + bar.get_width() / 2, height, f'{height:.1f}', ha='center', va='bottom')
        
        ax.set_xlabel(xlab)
        ax.set_ylabel('Mean Absolute Error')
        ax.set_xticks(x + (len(errors[xsub].unique()) - 1) * bar_width / 2, errors[xmain].unique())
        ax.set_xticklabels(errors[xmain].unique())
        #ax.set_title('Mean Absolute Error By # Searches and Field')
        plt.title(title)
        ax.legend()
        pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
        plt.close(fig)
################################################################################################################################
def make_abs_error_barplot_by_individual_search_field_combo(errors,comp,errmode,xmain,xsub,dlib=0):
    bar_width = 0.02
    spacing = .3        
    if xmain == 'searches':
        sort = 'Searches'
        xlab = 'Field'
    else:
        sort = 'Field'
        xlab = 'Searches'    
    compname = comp.upper()
    ofile = 'img/results/accuracy/hurricane_abserr_' + comp + '_' + errmode + '_combined_by-' + xmain 
    title = compname + ' ' + 'pressio:' + errmode + ' Mean Absolute Error By # Searches and Field'
    if dlib:
        ofile = ofile + '_dlib'
        title = title + ' with dlib'
    ofile = ofile + '.pdf'
    with PdfPages(ofile) as pdf_pages:
        x = np.arange(len(errors[xmain].unique()))
        x = x * spacing
        for xm in errors[xmain].unique():            
            main_data = errors[errors[xmain] == xm]            
            fig,ax = plt.subplots(figsize=(12,6))
            ax.bar(main_data[xsub],main_data['mean_abserr'],yerr=main_data['sem_abserr'],capsize=5)
            #bars = ax.bar(x + i * bar_width, field_data['mean_abserr'], width=bar_width, label=xm, yerr=field_data['sem_abserr'],capsize=5)            
            #for bar in bars:
                #height = bar.get_height()
                #ax.text(bar.get_x() + bar.get_width() / 2, height, f'{height:.1f}', ha='center', va='bottom')
            ax.set_xlabel(xlab)
            ax.set_ylabel('Mean Absolute Error')
            ax.set_title('Mean Absolute Error By # Searches and Field')
            plt.title(f'{compname} pressio:{errmode} Mean Absolute Error, {sort} = {xm}')
            pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
            plt.close(fig)                                
    

################################################################################################################################
def make_rel_error_barplot_by_searches_and_field(errors,comp,errmode,xmain,xsub,dlib=0):
    if xmain == 'searches':
        xlab = 'Searches'
        sort = 'Field'
    else:
        xlab = 'Field'
        sort = 'Searches' 
    
    bar_width = 0.03
    compname = comp.upper()    
    ofile = 'img/results/accuracy/hurricane_relerr_' + comp + '_' + errmode + '_combined_by-' + xmain
    title = compname + ' ' + 'pressio:' + errmode + ' Mean Relative Error By # Searches and Field'    
    if dlib:
        ofile = ofile + '_dlib'
        title = title + ' with dlib'
    ofile = ofile + '.pdf'
    with PdfPages(ofile) as pdf_pages:    
        fig,ax = plt.subplots(figsize=(12,6))        
        
        x = np.arange(len(errors[xmain].unique()))
        
        spacing = .35
        x = x * spacing
        
        for i, xs in enumerate(errors[xsub].unique()):
            field_data = errors[errors[xsub] == xs]
            bars = ax.bar(x + i * bar_width, field_data['mean_relerr'], width=bar_width, label=xs)
            for bar in bars:
                height = bar.get_height()
        
        ax.set_xlabel(xlab)
        ax.set_ylabel('Mean Relative Error')
        ax.set_xticks(x + (len(errors[xsub].unique()) - 1) * bar_width / 2, errors[xmain].unique())
        ax.set_xticklabels(errors[xmain].unique())
        plt.title(title)
        ax.legend()
        pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
        plt.close(fig)
################################################################################################################################
def make_rel_error_barplot_by_individual_search_field_combo(errors,comp,errmode,xmain,xsub,dlib=0):
    bar_width = 0.02
    spacing = .3        
    if xmain == 'searches':
        sort = 'Searches'
        xlab = 'Field'
    else:
        sort = 'Field'
        xlab = 'Searches'    
    compname = comp.upper()
    ofile = 'img/results/accuracy/hurricane_relerr_' + comp + '_' + errmode + '_combined_by-' + xmain 
    if dlib:
        ofile = ofile + '_dlib'
    ofile = ofile + '.pdf'
    with PdfPages(ofile) as pdf_pages:
        x = np.arange(len(errors[xmain].unique()))
        x = x * spacing
        for xm in errors[xmain].unique():            
            main_data = errors[errors[xmain] == xm]            
            fig,ax = plt.subplots(figsize=(12,6))
            ax.bar(main_data[xsub],main_data['mean_relerr'])#,yerr=main_data['sem_abserr'],capsize=5)     

            ax.set_xlabel(xlab)
            ax.set_ylabel('Mean Relative Error')
            ax.set_title('Mean Relative Error By # Searches and Field')
            plt.title(f'{compname} pressio:{errmode} Mean Relative Error, {sort} = {xm}')
            pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
            plt.close(fig)                                
    


        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
################################################################################################################################
def create_raw_cr_figs_animated(comp,field,errmode,cr_max):
    
    def get_data(t):
        timestep = f"{t:02d}"
        df = util.get_results(cfg.resultsdir, f'hurricane_{comp}_{field}f{timestep}_{errmode}')
        df = df[df['size:compression_ratio'] <= cr_max]
        x = df[cfg.X]
        y1 = df[cfg.Y]
        y2 = df[cfg.Z]
        return x, y1, y2
    
    fig, ax1 = plt.subplots()
    ax2 = ax1.twinx()
    
    ax1.set_xlim(0,1e-3)
    ax1.set_ylim(0,200)
    ax2.set_ylim(0,cr_max)
    
    line1 = ax1.plot([], [], lw=1, color='blue',label='PSNR')
    line2 = ax2.plot([], [], lw=1, color='red', label='Compression Ratio')
    
    def init():
        line1.set_data([],[])
        line2.set_data([],[])
        return line1, line2, #why is there a comma here??
    
    def animate(t):
        x, y1, y2 = get_data(t)
        line1.set_data(x, y1)
        line2.set_data(x, y2)
        return line1, line2
    
    num_frames = 48
    ani = animation.FuncAnimation(fig, animate, frames=num_frames, init_func=init, blit=True, interval=50)
    
    ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left')
    
    plt.show()
    
    
    for field in cfg.fields:
        with PdfPages(f'img/raw_crs/hurricane_{comp}_{field}_{errmode}_max_{cr_max}.pdf') as pdf_pages:
            results_df = util.get_results(cfg.resultsdir, f'hurricane_{comp}_{field}f*{errmode}')
            results_df = results_df[results_df['size:compression_ratio'] <= cr_max]
            
            for t in range(1,49):
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

                ax1.plot(x, z, color='blue')
                ax1.set_xlabel('Error Bound')
                ax1.set_ylabel('PSNR')
                ax1.tick_params(axis='y',labelcolor='blue')

                ax2 = ax1.twinx()
                ax2.plot(x, y, color='red')
                ax2.set_ylabel('Compression Ratio',rotation=180)
                ax2.tick_params(axis='y',labelcolor='red')

                lines1, labels1 = ax1.get_legend_handles_labels()
                lines2, labels2 = ax2.get_legend_handles_labels()
                ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left')
                plt.title(f'{field} {timestep} pressio:{errmode}')
                pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
                plt.close(fig)
            