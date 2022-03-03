import librosa
import matplotlib.pyplot as plt
import numpy as np
import os
from datetime import datetime
from pathlib import Path

def plot_file(path,normalize,show,timestamp):

    sr = 44100
    nfilters = 10
    fftSize = 2048
    output_dim_in = [10,4]
    dpi = 300

    mel_basis = librosa.filters.mel(sr=sr, n_fft=fftSize, n_mels=nfilters, fmin=20, fmax=20000)

    if not normalize:
        for i in range(len(mel_basis)):
            mel_basis[i] = mel_basis[i] / mel_basis[i].max()
    
    maxFilterHeight = np.max(mel_basis)

    mel_filter_centers = np.empty(len(mel_basis))

    for i, basis in enumerate(mel_basis):
        mel_filter_centers[i] = np.argmax(basis)

    pathname = Path(path)
    y, sr = librosa.load(str(pathname))
    # y, sr = librosa.load('Olencki-TenTromboneLongTones-M.wav')

    mags = np.abs(librosa.stft(y,n_fft=fftSize)).transpose()

    magIndex = 100
    magframe = mags[magIndex]  
    
    maxMag = np.max(magframe)      

    mels = np.zeros(nfilters)

    filtereds = []
    for i, base in enumerate(mel_basis):  
        filtered = base * magframe
        filtereds.append(filtered)
        mels[i] = np.sum(filtered)
        
    maxFilteredHeight = np.max(filtereds)

    prop_cycle = plt.rcParams['axes.prop_cycle']
    colors = prop_cycle.by_key()['color']

    def write_img(fig,ax0,id,label):
        ax0.set_xticks([])
        ax0.set_yticks([])
        ax0.axis('off')
        fig.tight_layout()
        # plt.subplots_adjust(hspace=0.6,left=0.08)
        fig.set_size_inches(output_dim_in[0],output_dim_in[1])
        p = Path(f'outputs/{timestamp}_transparent')
        p.mkdir(exist_ok=True)
        plt.savefig(p / f'{timestamp}_{pathname.stem}_norm={normalize}_{id}_{label}_{nfilters}_MelBands_frame={magIndex}.png',dpi=dpi,transparent=True)
         
    fig, ax = plt.subplots(1,1) 
    ax.plot([ampdb(val) for val in magframe],c='gray')
    ax.set_xlim([0,len(magframe)])
    ax.set_ylim([0,ampdb(maxMag)])
    write_img(fig,ax,0,'mags')

    for i in range(nfilters):
        fig, ax = plt.subplots(1,1)     
        ax.plot([ampdb(val) for val in mel_basis[i]],c=colors[i])
        label = f'triangleFilter{i}'
        ax.set_xlim([0,len(magframe)])
        ax.set_ylim([0,ampdb(maxFilterHeight)])
        write_img(fig,ax,1,label)
        print(label)
    
    for i in range(nfilters):
        fig, ax = plt.subplots(1,1)     
        ax.plot([ampdb(val) for val in filtereds[i]],c=colors[i])
        label = f'filteredSpectrum{i}'
        ax.set_xlim([0,len(magframe)])
        ax.set_ylim([0,ampdb(maxFilteredHeight)])
        write_img(fig,ax,2,label)
        print(label)

    fig, ax = plt.subplots(1,1)         
    for i in range(nfilters):
        
        ax.bar(mel_filter_centers[i],mels[i],10)
    label = f'melbandsSpaced'
    ax.set_xlim([0,len(magframe)])
    write_img(fig,ax,3,label)
    print(label)  

    fig, ax = plt.subplots(1,1)         
    for i in range(nfilters):
        ax.bar(i,mels[i],color=colors[i])
    label = f'melbands'
    write_img(fig,ax,4,label)
    print(label)  
        
# ======================================================================================
ts = datetime.now().strftime("%y%m%d_%H%M%S")

paths = ['Nicol-LoopE-M.wav']#'Olencki-TenTromboneLongTones-M.wav']#,'Nicol-LoopE-M.wav','Harker-DS-TenOboeMultiphonics-M.wav','Tremblay-CF-ChurchBells.wav']

for p in paths:
    plot_file(p,normalize=False,show=False,timestamp=ts)
for p in paths:
    plot_file(p,normalize=True,show=False,timestamp=ts)
