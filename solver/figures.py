import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sys
from pathlib import Path
import os
from scipy import stats
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import cfg
import util

################################################################################################################################
def create_raw_cr_figs(comp,errmode,cr_max):
    
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
                ax2.set_ylabel('Compression Ratio')
                ax2.tick_params(axis='y',labelcolor='red')

                lines1, labels1 = ax1.get_legend_handles_labels()
                lines2, labels2 = ax2.get_legend_handles_labels()
                ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left')
                plt.title(f'{field} {timestep} pressio:{errmode}')
                pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
                plt.close(fig)
                
################################################################################################################################
def create_raw_cr_figs_abs_and_rel(comp,cr_max):
    
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
                ax1_secondary.set_ylabel('Compression Ratio',color='black')
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
                ax2_secondary.set_ylabel('Compression Ratio',color='black')
                ax2_secondary.tick_params(axis='y',labelcolor='black')
                
                ax2.set_title('pressio:rel')

                lines3, labels3 = ax2.get_legend_handles_labels()
                lines4, labels4 = ax2_secondary.get_legend_handles_labels()
                ax2.legend(lines3 + lines4, labels3 + labels4, loc='upper left')   
                                
                ######################################################################

                fig.suptitle(f'{field} {timestep}',y=1.05)
                plt.tight_layout()
                pdf_pages.savefig(fig, bbox_inches='tight',dpi=600)
                plt.close(fig)                
                
################################################################################################################################
def make_error_barplot(errors,comp,):
    plt.bar(errors['searches'],errors['mean_abserr'], yerr=errors['sem_abserr'],capsize=5)
    plt.title(f'{comp} pressio:{errmode}')
    
################################################################################################################################
def make_error_barplot_by_searches_and_field(errors,comp):
    fig,ax = plt.subplots(figsize=(12,6))
    bar_width = 0.02

    x = np.arange(len(errors['searches'].unique()))

    spacing = .3
    x = x * spacing

    for i, field in enumerate(errors['field'].unique()):
        field_data = errors[errors['field'] == field]
        bars = ax.bar(x + i * bar_width, field_data['mean_abserr'], width=bar_width, label=field, yerr=field_data['sem_abserr'],capsize=5)
        for bar in bars:
            height = bar.get_height()
            #ax.text(bar.get_x() + bar.get_width() / 2, height, f'{height:.1f}', ha='center', va='bottom')

    #ax.set_xlim(left=0)

    # Add labels, title, and legend
    ax.set_xlabel('Searches')
    ax.set_ylabel('Mean Absolute Error')
    ax.set_title('Mean Absolute Error By # Searches and Field')
    ax.set_xticks(x + (len(errors['field'].unique()) - 1) * bar_width / 2, errors['searches'].unique())  # Center x-axis tick labels
    ax.set_xticklabels(errors['searches'].unique())
    ax.legend()

    #plt.xlim(min(x) - 0.01, max(x) + 0.01)

    # Show the plot
    plt.tight_layout()
    plt.show()

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


        linear_proxy = make_linear_proxy(df,X,Y)
        linear_approx = make_approx_fidelity(linear_proxy,sd)
        polynomial_proxy = make_polynomial_proxy(df,X,Y,deg)
        polynomial_approx = make_approx_fidelity(polynomial_proxy,sd)
        #objective_fx = on_error(linear_proxy, np.inf)
        objective_fx = on_error(linear_approx, np.inf)
        #objective_fx = on_error(polynomial_proxy, np.in



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

