import numpy as np
from numpy import genfromtxt
import matplotlib.pyplot as plt
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import RobustScaler

raw_data = genfromtxt("/Users/macprocomputer/Desktop/_flucoma/code/graphics/scaling example/210915_155924_drums_raw.csv",delimiter=',')

print('data')
print(raw_data)

normer = MinMaxScaler()

data_norm = normer.fit_transform(raw_data)
data_stan = StandardScaler().fit_transform(raw_data)
data_robu = RobustScaler().fit_transform(raw_data)

normer

fig, ax = plt.subplots(1,1)

def plot_data(data,ax_):
    ax_.scatter(data[:,0],data[:,1],marker='.')

plot_data(raw_data,ax)
plt.xlim([1000,10000])
plt.ylim([-5000,5000])
plt.ylabel('Loudness (dB)')
plt.xlabel('Spectral Centroid (Hz)')

plt.fig
plt.show()
