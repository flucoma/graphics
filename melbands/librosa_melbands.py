import librosa
import matplotlib.pyplot as plt
import numpy as np
import os
from datetime import datetime
from pathlib import Path
import math

epsilon = 1e-6

def ampdb(amp):
    return math.log10(amp+epsilon) * 20
    
def plot_file(path,normalize,show,timestamp,log=False):

    sr = 44100
    nfilters = 16
    fftSize = 2048
    output_dim_in = [10,10]
    dpi = 300

    mel_basis = librosa.filters.mel(sr=sr, n_fft=fftSize, n_mels=nfilters, fmin=20, fmax=20000)

    if not normalize:
        for i in range(len(mel_basis)):
            mel_basis[i] = mel_basis[i] / mel_basis[i].max()

    mel_filter_centers = np.empty(len(mel_basis))

    for i, basis in enumerate(mel_basis):
        mel_filter_centers[i] = np.argmax(basis)

    pathname = Path(path)
    y, sr = librosa.load(str(pathname))
    # y, sr = librosa.load('Olencki-TenTromboneLongTones-M.wav')

    mags = np.abs(librosa.stft(y,n_fft=fftSize)).transpose()

    magIndex = 100
    magframe = mags[magIndex]

    mels = np.zeros(nfilters)

    for i, base in enumerate(mel_basis):        
        mels[i] = np.sum(base * magframe)

    if log:
        mels = [ampdb(val) for val in mels]
        magframe = [ampdb(val) for val in magframe]   
        for i in range(len(mel_basis)):
            mel_basis[i] = [ampdb(val) for val in mel_basis[i]] 
    
    fig, ax = plt.subplots(4,1)

    ax[0].plot(magframe,c='gray')

    for i in range(nfilters):
        ax[1].plot(mel_basis[i]) 
        ax[2].bar(mel_filter_centers[i],mels[i],4)
        ax[3].bar(i,mels[i])

    ax[0].set_xlim([0,len(magframe)])
    ax[0].set_title("FFT Magnitudes")
    ax[1].set_xlim([0,len(magframe)])
    ax[1].set_title(f'{nfilters} MelBand Triangle Filters (normalize={normalize})')
    ax[2].set_xlim([0,len(magframe)])
    ax[2].set_title(f'{nfilters} MelBands aligned in frequency space with their Triangle Filters')
    ax[3].set_xticks(range(len(mels)))
    ax[3].set_title(f'{nfilters} MelBands')

    fig.tight_layout()

    plt.subplots_adjust(hspace=0.6,left=0.08)

    fig.set_size_inches(output_dim_in[0],output_dim_in[1])

    if show:
       plt.show()
    else:
        p = Path(f'outputs/{timestamp}_oneImage')
        p.mkdir(exist_ok=True)
        plt.savefig(p / f'{timestamp}_{pathname.stem}_norm={normalize}_log={log}_{nfilters}_MelBands_frame={magIndex}.png',dpi=dpi)

# ======================================================================================
ts = datetime.now().strftime("%y%m%d_%H%M%S")

paths = ['Olencki-TenTromboneLongTones-M.wav','Nicol-LoopE-M.wav','Harker-DS-TenOboeMultiphonics-M.wav','Tremblay-CF-ChurchBells.wav']

for p in paths:
    plot_file(p,normalize=True,show=False,timestamp=ts,log=False)
for p in paths:
    plot_file(p,normalize=False,show=False,timestamp=ts,log=False)
