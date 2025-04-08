import pandas as pd
# global variables/settings

X = "config:bound"
Y = "size:compression_ratio"
Z = "error_stat:psnr"

appdir = '/project/jonccal/fthpc/alpoulo/datasets/hurricane'
compresshome = '/project/jonccal/fthpc/alpoulo/repositories/Correlation_Compressibility'
solvedir = compresshome + '/solver'
resultsdir = solvedir + '/output/'
fields = ['CLOUD', 'PRECIP', 'P', 'QCLOUD', 'QGRAUP', 'QICE', 'QRAIN', 'QSNOW', 'QVAPOR', 'TC', 'U', 'V', 'W']

cr_max = 1000

def get_fields(app):
    if app == 'hurricane':
        fields = ['CLOUD', 'PRECIP', 'P', 'QCLOUD', 'QGRAUP', 'QICE', 'QRAIN', 'QSNOW', 'QVAPOR', 'TC', 'U', 'V', 'W']
        return fields
    elif app == 'NYX':
        fields = ['baryon_density','dark_matter_density', 'temperature','velocity_x','velocity_y','velocity_z']
        return fields
    else:
        print(f'error! invalid app: {app}\n')
        return None
    
def get_timesteps(app):
    if app == 'hurricane':
        timesteps = list(range(1,49))
        return timesteps
    elif app == 'NYX':
        timesteps = list(range(1,2))
        return timesteps
    else:
        print(f'error! invalid app: {app}\n')
        return None
    
    
def change_view():

    # Display all rows
    pd.set_option('display.max_rows', None)

    # Display all columns
    pd.set_option('display.max_columns', None)

    # Display full column width
    pd.set_option('display.max_colwidth', None)

    # Alternatively, set a large number for rows and columns
    # pd.set_option('display.max_rows', 1000)
    # pd.set_option('display.max_columns', 1000)

    # Display the DataFrame
    # print(df) # if you just want to print the dataframe
    # df # if you want the rich output in jupyter    
    
    
def reset_view():
    pd.reset_option('all')