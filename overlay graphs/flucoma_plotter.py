import numpy as np
from numpy import genfromtxt
from scipy.io import wavfile
from scipy import signal
import scipy
import matplotlib.pyplot as plt
from sklearn.preprocessing import MinMaxScaler
import csv

# FEATURES
features = []

#####################################################################################################
audio_path = "/Users/macprocomputer/Desktop/_flucoma/code/flucoma-sc/release-packaging/AudioFiles/Tremblay-ASWINE-ScratchySynth-M.wav"
x_samples = 1000
save_svg = False
save_png = True
show = False
output_dim_px = [1920,540]
dpi = 150

# WAVEFORM
waveform_color = (0,0,0) # black
waveform_alpha = 1
waveform_plot = 0

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
features.append({
    "color":(1,0,0),
    "alpha":1,
    "label":None,
    "axis":1,
    'plot':0,
    "data":None,
    'plot_strategy':'v_lines',
    'rescale_kind':'none',
    "path":"/Users/macprocomputer/Desktop/_flucoma/learn/slicing/scratchy_novelty.csv",
    'fill_between':True
    # "path":"/Users/macprocomputer/Desktop/_flucoma/drums_db.csv"
})

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

samplerate, raw_audio = wavfile.read(audio_path)
raw_audio = np.array(raw_audio)

def max_resample(arr,target_len,constant_vals = 0):
    n_pad_right = target_len - (len(arr) % target_len)

    arr = np.pad(arr,(0,n_pad_right),'constant',constant_values=(constant_vals,constant_vals))

    chunks = np.split(arr, target_len)
    return np.array([max(chunk) for chunk in chunks]).reshape(-1,1)

downsampled = max_resample(raw_audio,x_samples)
downsampled = np.array(MinMaxScaler().fit_transform(downsampled)).flatten()

def format_func(value,tick_number):
    # print(value)
    # print(samplerate)
    # print(x_samples)
    # print('')
    tick_val = np.round((value  / x_samples) * (len(raw_audio) / samplerate),1)
    return tick_val

def waveform_on_axis(wf,ax):
    ax.set_xlabel('time (sec)')
    ax.xaxis.set_major_formatter(plt.FuncFormatter(format_func))
    ax.set_ylabel('amplitude', color=waveform_color)
    fill_between_x = np.arange(0,x_samples,1)
    ax.fill_between(fill_between_x,wf,wf * -1,color=waveform_color,alpha=waveform_alpha,linewidth=0)
    ax.tick_params(axis='y', labelcolor=waveform_color)

def feature_on_axis(feature,ax):

    print(feature)
    # print(feature['path'])
    if feature['path'] != None:
        feature['data'] = genfromtxt(feature['path'],delimiter=',')
    # ax = ax1.twinx()  # instantiate a second axes that shares the same x-axis

    if feature['rescale_kind'] == 'linear':
        feature['data'] = signal.resample(feature['data'],x_samples)

    if feature['rescale_kind'] == 'max':
        feature['data'] = max_resample(feature['data'],x_samples,-1)
    
    if feature['label'] != None:
        ax.set_ylabel(feature['label'], color=feature['color'])  # we already handled the x-label with ax1
        ax.tick_params(axis='y', labelcolor=feature['color'])
    
    # feature['data'] = feature['data'].flatten()
    # print(feature['data'])
    # print(feature['data'].shape)
    # print(feature['data'].ndim)

    if feature['plot_strategy'] == 'fill_between':
        fill_between_x = np.arange(0,x_samples,1)
        ax.fill_between(fill_between_x,feature['data'],[np.min(feature['data']) for i in range(x_samples)],color=feature['color'],linewidth=0,alpha=feature['alpha'])
    elif feature['plot_strategy'] == 'v_lines':
        for x in feature['data']:
            print(x)
            plotx = (x / len(raw_audio)) * x_samples
            print(plotx)
            print("")
            ax.axvline(x=plotx,color=feature['color'],linewidth=1,alpha=feature['alpha'])
    else:
        ax.plot(feature['data'],color=feature['color'],alpha=feature['alpha'])

# if overlay:
#     fig, ax1 = plt.subplots()

#     # WAVEFORM
#     waveform_on_axis(downsampled,ax1)

#     # FEATURE
#     feature_on_axis(features[0],ax1.twinx())

#     # PLOT

# else:

n_plots = 0

for feature in features:
    n_plots = max(n_plots,feature['plot'])

n_plots = max(n_plots,waveform_plot) + 1

# print('nplots',n_plots)

fig, axes = plt.subplots(n_plots,1,sharex=True)

if not isinstance(axes,np.ndarray):
    axes = np.array([axes])

# print(axes)

waveform_on_axis(downsampled,axes[waveform_plot])
for feature in features:
    # print(feature)
    feature_on_axis(feature,axes[feature['plot']])

fig.tight_layout()  # otherwise the right y-label is slightly clipped
fig.set_size_inches(output_dim_px[0] / dpi, (output_dim_px[1] / dpi) * n_plots)
    
if save_svg:
    plt.savefig("test.svg",dpi=dpi)

if save_png:
    plt.savefig("test.png",dpi=dpi)

if show:
    plt.show()