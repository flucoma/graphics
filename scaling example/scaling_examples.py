import numpy as np
from numpy import genfromtxt
import matplotlib.pyplot as plt
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import RobustScaler
import csv
import os
import glob



colors = {
    # 'raw':(1,0,0),
    # 'norm':(0,1,0),
    # 'stand':(0,0,1),
    # 'robust':(0.6,0,1),
    'connector_lines':'#A1A5A6',
    'highlighted_line':'#F2B138',
    'lines':'#A1A5A6',
    'highlighted_dot':'#003F63',
    'dots':'#353D40'
}

output_dim_px = [1200,1200]
dpi = 150
show = False
save_to_png = True

if save_to_png:
    files = glob.glob('image_outputs/*')
    # print(files)
    for f in files:
        # print(f)
        os.remove(f)

raw_data = genfromtxt("drums_raw_data.csv",delimiter=',')
ids = []
id_to_idx = {}

with open("drums_raw_ids.csv","r") as csvfile:
    for i, row in enumerate(csv.reader(csvfile)):
        id = row[0]
        ids.append(id)
        id_to_idx[id] = i

# print('raw_data')
# print(raw_data)
# print('ids')
# print(ids)
# print(id_to_idx)

normer = MinMaxScaler()
stander = StandardScaler()
robuster = RobustScaler()
# robuster = RobustScaler(quantile_range=(10,90))

data_norm = normer.fit_transform(raw_data)
data_stan = stander.fit_transform(raw_data)
data_robu = robuster.fit_transform(raw_data)

# fig, ax = plt.subplots(1,1)

def plot_data(data,ax_):
    ax_.scatter(data[:,0],data[:,1],marker='.',color=colors['dots'])

# raw
def raw_plot(xmin=0,xmax=10000,ymin=-5000,ymax=5000):
    fig, ax = plt.subplots(1,1)
    plot_data(raw_data,ax)
    plt.xlim([xmin,xmax])
    plt.ylim([ymin,ymax])
    plt.ylabel('Loudness (dB)')
    plt.xlabel('Spectral Centroid (Hz)')
    return fig, ax

# norm
def norm_plot():
    fig, ax = plt.subplots(1,1)

    plot_data(data_norm,ax)
    xmin = -0.1
    xmax = 1.1
    ymin = -0.1
    ymax = 1.1
    ax.vlines(0,ymin,ymax,linestyles='-',colors=colors['lines'],alpha=0.5)
    ax.hlines(0,xmin,xmax,linestyles='-',colors=colors['lines'],alpha=0.5)
    ax.vlines(1,ymin,ymax,linestyles='--',colors=colors['lines'],alpha=0.5)
    ax.hlines(1,xmin,xmax,linestyles='--',colors=colors['lines'],alpha=0.5)
    plt.xlim([xmin,xmax])
    plt.ylim([ymin,ymax])
    plt.ylabel('Loudness (normalized)')
    plt.xlabel('Spectral Centroid (normalized)')
    return fig, ax

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
    ax.vlines(0,ymin,ymax,linestyles='-',colors=colors['lines'],alpha=0.5)
    ax.hlines(0,xmin,xmax,linestyles='-',colors=colors['lines'],alpha=0.5)
    ax.vlines(1,ymin,ymax,linestyles='--',colors=colors['lines'],alpha=0.5)
    ax.hlines(1,xmin,xmax,linestyles='--',colors=colors['lines'],alpha=0.5)
    ax.vlines(-1,ymin,ymax,linestyles='--',colors=colors['lines'],alpha=0.5)
    ax.hlines(-1,xmin,xmax,linestyles='--',colors=colors['lines'],alpha=0.5)
    plt.ylabel('Loudness (standardized)')
    plt.xlabel('Spectral Centroid (standardized)')
    return fig, ax

def robust_plot():
    fig, ax = plt.subplots(1,1)

    plot_data(data_robu,ax)
    xmin = -3
    xmax = 3
    ymin = -3
    ymax = 3
    plt.xlim([xmin,xmax])
    plt.ylim([ymin,ymax])
    ax.vlines(0,ymin,ymax,linestyles='-',colors=colors['lines'],alpha=0.5)
    ax.hlines(0,xmin,xmax,linestyles='-',colors=colors['lines'],alpha=0.5)
    
    ax.vlines(-0.1680524200201,ymin,ymax,linestyles='--',colors=colors['lines'],alpha=0.5)
    ax.vlines(0.83194756507874,ymin,ymax,linestyles='--',colors=colors['lines'],alpha=0.5)

    ax.hlines(-0.54100561141968,xmin,xmax,linestyles='--',colors=colors['lines'],alpha=0.5)    
    ax.hlines(0.458994358778,xmin,xmax,linestyles='--',colors=colors['lines'],alpha=0.5)

    plt.ylabel('Loudness (robust scaler)')
    plt.xlabel('Spectral Centroid (robust scaler)')
    return fig, ax

image_counter = 0

def show_or_save(fig,ax,name,image_counter):
    # fig.tight_layout() 
    fig.set_size_inches(output_dim_px[0] / dpi, (output_dim_px[1] / dpi))
    
    if show:
       plt.show()
    if save_to_png:
        plt.savefig(f'image_outputs/{image_counter:02}_{name}.png',dpi=dpi)
        image_counter += 1
    return image_counter

def connect_two_ids(data,id0,id1,ax_,color,xoff=0.05,yoff=-0.05):
    idx0 = id_to_idx[id0]
    idx1 = id_to_idx[id1]
    x = [data[idx0][0],data[idx1][0]]
    y = [data[idx0][1],data[idx1][1]]
    ax_.plot(x,y,linestyle='-',color=color)

def label_point(id,data,ax_,xoff=0.05,yoff=-0.05,change_color=False):
    idx = id_to_idx[id]
    pos = data[idx]
    ax_.text(pos[0] + xoff,pos[1] + yoff,id)
    if change_color:
        # print(colors['highlighted_dot'])
        ax_.scatter(pos[0],pos[1],marker='o',color=colors['highlighted_dot'])

# ===========================================================================

# RAW
fig, ax = raw_plot()
image_counter = show_or_save(fig,ax,'raw',image_counter)

label_point('slice-27',raw_data,ax,50,-300,change_color=True)
image_counter = show_or_save(fig,ax,'raw with one label',image_counter)

label_point('slice-21',raw_data,ax,-800,150,True)
connect_two_ids(raw_data,"slice-27","slice-21",ax,colors['highlighted_line'])
image_counter = show_or_save(fig,ax,'raw with neighbor',image_counter)

# RAW ZOOMED
fig, ax = raw_plot(2500,3500,-500,500)
# image_counter = show_or_save(fig,ax,'raw',image_counter)

label_point('slice-27',raw_data,ax,5,-30,change_color=True)
# image_counter = show_or_save(fig,ax,'raw with one label',image_counter)

label_point('slice-21',raw_data,ax,-80,12,True)
connect_two_ids(raw_data,"slice-27","slice-21",ax,colors['highlighted_line'])
image_counter = show_or_save(fig,ax,'raw with neighbor zoomed',image_counter)

# NORM
fig, ax = norm_plot()
image_counter = show_or_save(fig,ax,'norm',image_counter)
xoff = 0.02
yoff = -0.01
label_point('slice-27',data_norm,ax,xoff,yoff,True)
image_counter = show_or_save(fig,ax,'norm with one labeled point',image_counter)

label_point('slice-21',data_norm,ax,xoff,yoff+0.025,True)
image_counter = show_or_save(fig,ax,'norm 2 labeled points',image_counter)

connect_two_ids(data_norm,"slice-27","slice-21",ax,colors['connector_lines'])
image_counter = show_or_save(fig,ax,'norm 2 labeled points and the line',image_counter)

label_point('slice-13',data_norm,ax,xoff,yoff,True)
connect_two_ids(data_norm,"slice-27","slice-13",ax,colors['highlighted_line'])
image_counter = show_or_save(fig,ax,'norm with 2 neighbors',image_counter)

# STAND
fig, ax = stand_plot()
image_counter = show_or_save(fig,ax,'standardized',image_counter)
xoff = 0.05
yoff = 0.05
connect_two_ids(data_stan,"slice-27","slice-21",ax,colors['connector_lines'])
label_point('slice-27',data_stan,ax,xoff,yoff,True)
label_point('slice-21',data_stan,ax,xoff,yoff,True)
image_counter = show_or_save(fig,ax,'standardized with 1 neighbor',image_counter)

connect_two_ids(data_stan,"slice-27","slice-13",ax,colors['connector_lines'])
label_point('slice-13',data_stan,ax,xoff+0.05,yoff-0.2,True)
image_counter = show_or_save(fig,ax,'stand with 2 neighbors',image_counter)

connect_two_ids(data_stan,"slice-27","slice-23",ax,colors['highlighted_line'])
label_point('slice-23',data_stan,ax,xoff-0.6,yoff,True)
image_counter = show_or_save(fig,ax,'stand with 3 neighbors',image_counter)

# ROBUST
fig, ax = robust_plot()
image_counter = show_or_save(fig,ax,'robust',image_counter)
xoff = 0.05
yoff = 0.05
connect_two_ids(data_robu,"slice-27","slice-21",ax,colors['connector_lines'])
label_point('slice-27',data_robu,ax,xoff,yoff,True)
label_point('slice-21',data_robu,ax,xoff,yoff,True)
image_counter = show_or_save(fig,ax,'robust with 1 neighbor',image_counter)

connect_two_ids(data_robu,"slice-27","slice-13",ax,colors['connector_lines'])
label_point('slice-13',data_robu,ax,xoff,yoff,True)
image_counter = show_or_save(fig,ax,'robust with 2 neighbors',image_counter)

connect_two_ids(data_robu,"slice-27","slice-23",ax,colors['highlighted_line'])
label_point('slice-23',data_robu,ax,xoff-0.6,yoff,True)
image_counter = show_or_save(fig,ax,'robust with 3 neighbors',image_counter)