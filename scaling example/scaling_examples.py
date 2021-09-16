import numpy as np
from numpy import genfromtxt
import matplotlib.pyplot as plt
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import RobustScaler

output_dim_px = [4000,2000]
dpi = 150
show = True
save_to_png = False

raw_data = genfromtxt("210915_155924_drums_raw.csv",delimiter=',')

# print('data')
# print(raw_data)

normer = MinMaxScaler()
stander = StandardScaler()
robuster = RobustScaler()

data_norm = normer.fit_transform(raw_data)
data_stan = stander.fit_transform(raw_data)
data_robu = robuster.fit_transform(raw_data)

fig, ax = plt.subplots(1,1)

def plot_data(data,ax_):
    ax_.scatter(data[:,0],data[:,1],marker='.')

# raw
def raw_plot():
    plot_data(raw_data,ax)
    plt.xlim([1000,10000])
    plt.ylim([-5000,5000])
    plt.ylabel('Loudness (dB)')
    plt.xlabel('Spectral Centroid (Hz)')

    fig.tight_layout()  # otherwise the right y-label is slightly clipped
    fig.set_size_inches(output_dim_px[0] / dpi, (output_dim_px[1] / dpi))

    if show:
       plt.show()
    if save_to_png:
        plt.savefig("raw.png")

# norm
def norm_plot():
    fig, ax = plt.subplots(1,1)

    plot_data(data_norm,ax)
    ax.vlines(0,-0.2,1.2,linestyles='-',colors=(1,0,0),alpha=0.5)
    ax.hlines(0,-0.2,1.2,linestyles='-',colors=(1,0,0),alpha=0.5)
    ax.vlines(1,-0.2,1.2,linestyles='--',colors=(1,0,0),alpha=0.5)
    ax.hlines(1,-0.2,1.2,linestyles='--',colors=(1,0,0),alpha=0.5)
    plt.xlim([-0.2,1.2])
    plt.ylim([-0.2,1.2])
    plt.ylabel('Loudness (normalized)')
    plt.xlabel('Spectral Centroid (normalized)')

    fig.tight_layout()  # otherwise the right y-label is slightly clipped
    fig.set_size_inches(output_dim_px[0] / dpi, (output_dim_px[1] / dpi))

    if show:
       plt.show()
    if save_to_png:
        plt.savefig("normalized.png")


# stand
def stand_plot():
    fig, ax = plt.subplots(1,1)

    plot_data(data_stan,ax)
    xmin = -3
    xmax = 3
    ymin = -3
    ymax = 3
    plt.xlim([xmin,xmax])
    plt.ylim([ymin,ymax])
    ax.vlines(0,ymin,ymax,linestyles='-',colors=(1,0,0),alpha=0.5)
    ax.hlines(0,xmin,xmax,linestyles='-',colors=(1,0,0),alpha=0.5)
    ax.vlines(1,ymin,ymax,linestyles='--',colors=(1,0,0),alpha=0.5)
    ax.hlines(1,xmin,xmax,linestyles='--',colors=(1,0,0),alpha=0.5)
    ax.vlines(-1,ymin,ymax,linestyles='--',colors=(1,0,0),alpha=0.5)
    ax.hlines(-1,xmin,xmax,linestyles='--',colors=(1,0,0),alpha=0.5)
    plt.ylabel('Loudness (standardized)')
    plt.xlabel('Spectral Centroid (standardized)')

    fig.tight_layout()  # otherwise the right y-label is slightly clipped
    fig.set_size_inches(output_dim_px[0] / dpi, (output_dim_px[1] / dpi))

    if show:
       plt.show()
    if save_to_png:
        plt.savefig("standardized.png")

def robust_plot():
    fig, ax = plt.subplots(1,1)

    plot_data(data_robu,ax)
    xmin = -3
    xmax = 3
    ymin = -3
    ymax = 3
    plt.xlim([xmin,xmax])
    plt.ylim([ymin,ymax])
    ax.vlines(0,ymin,ymax,linestyles='-',colors=(1,0,0),alpha=0.5)
    ax.hlines(0,xmin,xmax,linestyles='-',colors=(1,0,0),alpha=0.5)
    
    ax.vlines(-0.1680524200201,ymin,ymax,linestyles='--',colors=(1,0,0),alpha=0.5)
    ax.vlines(0.83194756507874,ymin,ymax,linestyles='--',colors=(1,0,0),alpha=0.5)

    ax.hlines(-0.54100561141968,xmin,xmax,linestyles='--',colors=(1,0,0),alpha=0.5)    
    ax.hlines(0.458994358778,xmin,xmax,linestyles='--',colors=(1,0,0),alpha=0.5)

    plt.ylabel('Loudness (robust scaler)')
    plt.xlabel('Spectral Centroid (robust scaler)')

    fig.tight_layout()  # otherwise the right y-label is slightly clipped
    fig.set_size_inches(output_dim_px[0] / dpi, (output_dim_px[1] / dpi))

    if show:
       plt.show()
    if save_to_png:
        plt.savefig("robust scaler.png")

# stand_norm = MinMaxScaler()
# stand_norm.fit(data_stan)
# print(stand_norm.data_min_)
# print(stand_norm.data_max_)

# robust_norm = MinMaxScaler()
# robust_norm.fit(data_robu)
# print(robust_norm.data_min_)
# print(robust_norm.data_max_)
# print('n points:',len(raw_data))

print('center',robuster.center_)
print('scale',robuster.scale_)

raw_plot()
norm_plot()
stand_plot()
robust_plot()
