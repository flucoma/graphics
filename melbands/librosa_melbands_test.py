import librosa
import matplotlib.pyplot as plt

sr = 44100
nfilters = 16
mel_basis = librosa.filters.mel(sr=sr, n_fft=1024, n_mels=nfilters,fmin=0, fmax=sr / 2)

fig, ax = plt.subplots(2,1)

mel_basis.shape
for i in range(nfilters):
    ax[0].plot(mel_basis[i]) #normalized filter
    ax[1].plot(mel_basis[i] / mel_basis[i].max()) #unnormalised filter
plt.show()
