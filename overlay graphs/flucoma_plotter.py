import numpy as np
from numpy import genfromtxt
from scipy.io import wavfile
from scipy import signal
import scipy
import matplotlib.pyplot as plt
from sklearn.preprocessing import MinMaxScaler
import csv
import json
import argparse

# FEATURES
# features = []

#####################################################################################################

# WAVEFORM

# loudness
# features.append({
#     "color":(0,0.588,1), # flucoma blue
#     "alpha":1,
#     "label":"Loudness (dB)",
#     "axis":0,
#     'plot':0,
#     'rescale_kind':'linear',
#     'fill_between':True,
#     "path":"/Users/macprocomputer/Desktop/_flucoma/drums_db.csv",
#     'data':None
# })

# threhold
# features.append({
#     "color":(0.8,0.8,0.8),
#     "alpha":1,
#     "label":None,
#     "axis":0,
#     "plot":0,
#     'rescale_kind':'linear',
#     "data":np.full((x_samples,),-20),
#     "path":None,
#     'fill_between':False
#     # "path":"/Users/macprocomputer/Desktop/_flucoma/drums_db.csv"
# })

# novelty
# features.append({
#     "color":(1,0,0),
#     "alpha":1,
#     "label":None,
#     "axis":1,
#     'plot':0,
#     "data":None,
#     'plot_strategy':'v_lines',
#     'rescale_kind':'none',
#     "path":"/Users/macprocomputer/Desktop/_flucoma/learn/slicing/scratchy_novelty.csv",
#     'fill_between':True
#     # "path":"/Users/macprocomputer/Desktop/_flucoma/drums_db.csv"
# })

# features.append({
#     "color":(1,1,0.1),
#     "alpha":0.8,
#     "label":'Fluid Amp Gate',
#     "axis":1,
#     'plot':0,
#     "data":None,
#     'rescale_kind':'max',
#     "path":"/Users/macprocomputer/Desktop/_flucoma/learn/slicing/Nicol_AmpGate.csv",
#     'fill_between':True
#     # "path":"/Users/macprocomputer/Desktop/_flucoma/drums_db.csv"
# })

#####################################################################################################
def max_resample(arr,target_len,constant_vals = 0):
    n_pad_right = target_len - (len(arr) % target_len)

    arr = np.pad(arr,(0,n_pad_right),'constant',constant_values=(constant_vals,constant_vals))

    chunks = np.split(arr, target_len)
    return np.array([max(chunk) for chunk in chunks]).reshape(-1,1)

def resample(feature,x_samples):
    if feature['resample'] == 'max':
        return max_resample(feature['data'],x_samples,constant_vals=np.min(feature['data']))
    elif feature['resample'] == 'linear':
        return signal.resample(feature['data'],x_samples)
    else:
        return feature['data']

def process_fill(feature,ax,x_samples):
    feature = check_feature_for_data(feature)

    if 'resample' in feature.keys():
        feature['data'] = resample(feature,x_samples)

    fill_between_x = np.arange(0,x_samples,1)
    y1 = feature['data'].flatten()
    y2 = np.array([np.min(feature['data']) for i in range(x_samples)])

    # print(y1)
    ax[feature['plot']].fill_between(fill_between_x,y1,y2,color=feature['color'],linewidth=0,alpha=feature['alpha'])
    if feature['label'] != None:
        ax[feature['plot']].set_ylabel(feature['label'], color=feature['color'])
        ax[feature['plot']].tick_params(axis='y', labelcolor=feature['color'])

# def feature_on_axis(feature,ax,x_samples):

#     print(feature)
#     # print(feature['path'])
#     if feature['path'] != None:
#         feature['data'] = genfromtxt(feature['path'],delimiter=',')
#     # ax = ax1.twinx()  # instantiate a second axes that shares the same x-axis

#     if feature['rescale'] == 'linear':
#         feature['data'] = signal.resample(feature['data'],x_samples)

#     if feature['rescale_kind'] == 'max':
#         feature['data'] = max_resample(feature['data'],x_samples,-1)
    
#     if feature['label'] != None:
#         ax.set_ylabel(feature['label'], color=feature['color'])  # we already handled the x-label with ax1
#         ax.tick_params(axis='y', labelcolor=feature['color'])

#     if feature['plot_strategy'] == 'fill_between':
#         fill_between_x = np.arange(0,x_samples,1)
#         ax.fill_between(fill_between_x,feature['data'],[np.min(feature['data']) for i in range(x_samples)],color=feature['color'],linewidth=0,alpha=feature['alpha'])
#     else:
#         ax.plot(feature['data'],color=feature['color'],alpha=feature['alpha'])    

def process_waveform(feature,axes,x_samples):
    feature['path']
    samplerate, raw_audio = wavfile.read(feature['path'])
    raw_audio = np.array(raw_audio)

    downsampled = max_resample(raw_audio,x_samples)
    downsampled = np.array(MinMaxScaler().fit_transform(downsampled)).flatten()
    # waveform_on_axis(downsampled,axes[feature['plot']])
    axes[feature['plot']].set_xlabel('time (sec)')
    def format_func(value,tick_number):
        tick_val = np.round((value  / x_samples) * (len(raw_audio) / samplerate),1)
        return tick_val 
    axes[feature['plot']].xaxis.set_major_formatter(plt.FuncFormatter(format_func))
    axes[feature['plot']].set_ylabel('amplitude', color=feature['color'])
    fill_between_x = np.arange(0,x_samples,1)
    axes[feature['plot']].fill_between(fill_between_x,downsampled,downsampled * -1,color=feature['color'],alpha=feature['alpha'],linewidth=0)
    axes[feature['plot']].tick_params(axis='y', labelcolor=feature['color'])

def check_feature_for_data(feature):
    if 'data' not in feature.keys():
        feature['data'] = genfromtxt(feature['path'],delimiter=',')
    return feature

def process_vlines(feature,axes,x_samples):
    feature = check_feature_for_data(feature)
    
    _, raw_audio = wavfile.read(feature['source_audio'])
    for x in feature['data']:
        # print(x)
        plotx = (x / len(raw_audio)) * x_samples
        # print(plotx)
        # print("")
        axes[feature['plot']].vlines(x=plotx,ymin=feature['ymin'],ymax=feature['ymax'],color=feature['color'],linewidth=1,alpha=feature['alpha'])

def process_hlines(feature,axes,x_samples):
    for y in feature['data']:
        axes[feature['plot']].hlines(y=y,xmin=0,xmax=x_samples,color=feature['color'],linewidth=1,alpha=feature['alpha'])


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--input','-i',type=str,dest='input')
    args = parser.parse_args()

    with open(args.input) as jsonfile:
        dict = json.load(jsonfile)

        # how many plots do we have to make
        n_plots = 0
        for feature in dict['features']:
            n_plots = max(n_plots,feature['plot'])

        n_plots += 1

        fig, axes = plt.subplots(n_plots,1,sharex=True)

        # for array to simplify later
        if not isinstance(axes,np.ndarray):
            axes = np.array([axes])

        # THE ACTUAL PLOTTING
        types = {
            "waveform":process_waveform,
            "vlines":process_vlines,
            "hlines":process_hlines,
            "fill":process_fill,
        }

        for feature in dict['features']:
            types[feature['type']](feature,axes,dict['x_samples'])

        # FORMATTING
        fig.tight_layout()
        fig.set_size_inches(dict['output_dim_px'][0] / dict['dpi'], (dict['output_dim_px'][1] / dict['dpi']))
        
        # EXPORTING
        if dict['save_svg']:
            plt.savefig("test.svg",dpi=dict['dpi'])

        if dict['save_png']:
            plt.savefig("test.png",dpi=dict['dpi'])

        if dict['show']:
            plt.show()