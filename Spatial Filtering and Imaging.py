import numpy as np
from PIL import Image
import matplotlib.pyplot as plt
from scipy.signal import fftconvolve

xy_start = -50                                   # 输入物面观测范围,大致取有效范围 1.3 - 1.7 倍
xy_end = +50                                     # 图片范围：[-50,50]*[-50,50],外围补零
xy_intervals = 1001                              # 输入xy方向绘图间隔
xy_astart = -100                                 # 扩展
xy_aend = +100
xy_aintervals = 2001

r = 210                                          # 透镜半径(单位:μm)
f = 100                                          # 透镜焦距(单位:μm)
wavelength = 0.633                               # 入射波波长(单位:μm)
n = xy_intervals                                 # 读入图片像素(n*n)，按原像素读入
k = 2 * np.pi / wavelength
path = 'circle.png'       # 'ustc.png' 'photo.png' 'grating.png' 'star.png'

def digitalize(image_path, target_size):
    with Image.open(image_path) as img:
        gray_img = img.convert('L')         # 将图像转换为灰度图
        resized_img = gray_img.resize(target_size, Image.Resampling.LANCZOS)    # 调整大小
        img_array = np.array(resized_img)   # 转换为NumPy数组
        return img_array                    # 255,白; 0,黑

def digitalize_phase(image_path, target_size, threshold=128, phase_max=0.3, invert=False):
    with Image.open(image_path) as img:
        gray_img = img.convert('L')
        resized_img = gray_img.resize(target_size, Image.Resampling.LANCZOS)
        arr = np.array(resized_img, dtype=np.float64)
    # ---- 二值化：只有 0 / 1 ----
    binary = (arr > threshold).astype(np.float64)
    if invert:
        binary = 1.0 - binary

    phase = binary * phase_max
    field = np.exp(1j * phase)
    return field

def rs_kernel(x,y,z):
    r_0 = np.sqrt(x**2 + y**2 + z**2)
    result = (1j * k - (1 / r_0)) * np.exp(1j * k * r_0) * z / (-2 * np.pi * r_0**2)
    return result
def transfer(X,Y,z,U_0):
    u = U_0
    g = rs_kernel(X,Y,z)
    result = fftconvolve(u,g,mode='same')
    return result
def lens(x,y,r,k,f):
    result = np.where((x ** 2 + y ** 2) <= r ** 2, np.exp(-0.5 * 1j * k * (x**2+y**2) / f), 0)
    return result

def high_wave(x,y,r):   # 半径为 r 的高通滤波器
    result = np.where((x ** 2 + y ** 2) <= r ** 2, 0, 1)
    return result
def low_wave(x,y,r):    # 半径为 r 的低通滤波器
    result = np.where((x ** 2 + y ** 2) <= r ** 2, 1, 0)
    return result

def custom_filter(x, y):    # 滤除图像条纹的滤波器
    mask1 = (x >= -10) & (x <= 10) & (y >= 45) & (y <= 65)
    mask2 = (x >= -10) & (x <= 10) & (y >= -65) & (y <= -45)
    result = np.where(mask1 | mask2, 0, 1)
    return result

def phase_contrast_plate(x,y,r, delta = 0.5 * np.pi, t=0.5):    # 半径为 r 的 exp(iδ) 相移板
    result = np.where((x ** 2 + y ** 2) <= r ** 2, t*np.exp(1j * delta), 1)
    return result

def expand_m(matrix, m):
    n = matrix.shape[0]
    pad_size = (m - n) // 2
    expanded_matrix = np.zeros((m, m), dtype=matrix.dtype)
    expanded_matrix[pad_size:pad_size + n, pad_size:pad_size + n] = matrix # 将原矩阵复制到新矩阵的正中
    return expanded_matrix

# 读入黑白化振幅物
object_0 = np.flipud(digitalize(path, (n, n)))
object_0 = (object_0 - object_0.min()) / (object_0.max() - object_0.min()) # 输入图片：衍射屏（振幅物/相位物）
## 读入相位物（phi=0.05）              # 有问题时phase_max调大查一下
#object_0 = np.flipud(digitalize_phase(path, (n, n),threshold=128, phase_max=0.3,invert=False))

object_0 = expand_m(object_0,xy_aintervals)

x = np.linspace(xy_astart, xy_aend, xy_aintervals)
y = np.linspace(xy_astart, xy_aend, xy_aintervals)
X, Y = np.meshgrid(x,y)             # 生成中心基准坐标网
lens_trans = lens(X,Y,r,k,f)            # 频谱面透镜变换

spectrum_1 = transfer(X,Y,f,object_0)           # 第一次衍射传输：物面--透镜前表面
after_lens = spectrum_1 * lens_trans            # 透镜后表面
U_spec = transfer(X,Y,f,after_lens)             # 第二次衍射传输：透镜后表面物--频谱面

# 【实验一】光栅、圆孔、五角星的夫琅禾费衍射 —— 调成振幅物
U_modulate = U_spec                             # 直接传输

# 【实验二】4F成像系统 与 高通低通滤波 —— 用五角星图片操作
#U_modulate = U_spec * high_wave(X,Y,3)         # 半径为3的高通滤波器
#U_modulate = U_spec * high_wave(X,Y,10)        # 半径为10的高通滤波器
#U_modulate = U_spec * low_wave(X,Y,12)         # 半径为12的低通滤波器
#U_modulate = U_spec * low_wave(X,Y,5)          # 半径为5的低通滤波器

# 【实验三】空间滤波 —— 用photo操作
#U_modulate = U_spec                            # 直接传输
#U_modulate = U_spec * custom_filter(X, Y)      # 挡掉条纹对应的高频频谱成分

# 【实验四】弱相位物的相衬法 —— 调成相位物
#U_modulate = U_spec                            # 直接传输
                                                # 相衬法，相移pi/2，衰减0.5;
#U_modulate = U_spec * phase_contrast_plate(X,Y,0.8, delta = 0.5 * np.pi, t=0.5)

spectrum_2 = transfer(X,Y,f,U_modulate)         # 第三次衍射传输：频谱面--透镜前表面
after_lens2 = spectrum_2 * lens_trans           # 透镜后表面
U_image = transfer(X,Y,f,after_lens2)           # 第四次衍射传输：透镜后表面物--像面

# ===========================
# 七个关键平面的光场分布
# ===========================
# 1. 物面振幅：裁到原始范围
pad = (xy_aintervals - n) // 2                #  500
obj_show = object_0[pad:pad+n, pad:pad+n]     # 1001×1001
A_object = np.abs(obj_show)

# 2. 物面相位
# P_object = np.angle(object_0)

# 3. 频谱面振幅（调制前）
A_spec = np.abs(U_spec)

# 4. 频谱面相位（调制前）
# P_spec = np.angle(U_spec)

# 5. 频谱面振幅（调制后）
A_modulate = np.abs(U_modulate)

# 6. 频谱面相位（调制后）
# P_modulate = np.angle(U_modulate)

# 7. 像面强度
Intensity = np.abs(U_image)**2


# ===========================
# 绘图函数
# ===========================

def plot_distribution(ax, data, title, cmap,
                      extent, vmin=None, vmax=None,
                      colorbar_label=''):

    im = ax.imshow(
        data,
        extent=extent,
        cmap=cmap,
        origin='lower',
        aspect='equal',
        vmin=vmin,
        vmax=vmax
    )

    ax.set_title(title, fontsize=13)
    ax.set_xlabel('x (μm)', fontsize=11)
    ax.set_ylabel('y (μm)', fontsize=11)

    plt.colorbar(
        im, ax=ax,
        orientation='vertical',
        fraction=0.046,
        pad=0.04,
        label=colorbar_label
    )


# ===========================
# 振幅归一化
# ===========================

A_object = A_object / A_object.max()
A_spec = A_spec / A_spec.max()
A_modulate = A_modulate / A_modulate.max()

Intensity = Intensity / Intensity.max()


# ===========================
# 相位显示
# ===========================

# 振幅接近零的区域，相位没有物理意义
def get_phase(field):
    amplitude = np.abs(field)
    phase = np.angle(field)

    phase = np.ma.masked_where(
        amplitude < amplitude.max() * 1e-8,
        phase
    )
    return phase


P_object = get_phase(obj_show)
P_spec = get_phase(U_spec)
P_modulate = get_phase(U_modulate)


# ===========================
# 七张图
# ===========================

fig, axes = plt.subplots(2, 4, figsize=(20, 9))

extent = [xy_astart, xy_aend, xy_astart, xy_aend]
extent_origin = [xy_start, xy_end, xy_start, xy_end]

# 第一行：物面、频谱面（调制前）
plot_distribution(
    axes[0, 0], A_object,
    'Object Amplitude', 'gray', extent_origin,
    0, 1, 'Normalized Amplitude'
)

plot_distribution(
    axes[0, 1], P_object,
    'Object Phase', 'twilight', extent_origin,
    -np.pi, np.pi, 'Phase (rad)'
)

plot_distribution(
    axes[0, 2], A_spec,
    'Fourier Amplitude', 'gray', extent,
    0, 1, 'Normalized Amplitude'
)

plot_distribution(
    axes[0, 3], P_spec,
    'Fourier Phase', 'twilight', extent,
    -np.pi, np.pi, 'Phase (rad)'
)

# 第二行：频谱面（调制后）、像面
plot_distribution(
    axes[1, 0], A_modulate,
    'Modulated Fourier Amplitude', 'gray', extent,
    0, 1, 'Normalized Amplitude'
)

plot_distribution(
    axes[1, 1], P_modulate,
    'Modulated Fourier Phase', 'twilight', extent,
    -np.pi, np.pi, 'Phase (rad)'
)

plot_distribution(
    axes[1, 2], Intensity,
    'Image Intensity', 'jet', extent,
    0, 1, 'Normalized Intensity'
)

plot_distribution(
    axes[1, 3], Intensity,
    'Image Intensity (black & white)', 'gray', extent,
    0, 1, 'Normalized Intensity'
)

plt.tight_layout()
plt.show()