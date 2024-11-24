import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import lfilter, firwin

file = open('earthq.txt', 'r')
data = file.read().splitlines()
file.close()
x = np.linspace(1, 1000, 1000)
for i in range(len(data)):
    data[i] = float(data[i])
data = np.array(data)

plt.figure(figsize=(1000,6))
plt.plot(x, data, 'r')   # red line without marker
plt.show()

fs = 1000
numtaps = 101  # 濾波器的抽頭數 (必須為奇數)
cutoff = 100  # 截止頻率 (Hz)
fir_coeff = firwin(numtaps, cutoff, fs=fs, pass_zero='lowpass')  # 低通濾波器設計
filtered_signal = lfilter(fir_coeff, 1.0, data)

plt.figure(figsize=(1000,6))
plt.plot(x, filtered_signal, 'r')   # red line without marker
plt.show()

for i in range(int(1000/16)):
    n = len(filtered_signal[i*16:(i+1)*16])  # 訊號長度
    fft_result = np.fft.fft(filtered_signal[i*16:(i+1)*16])  # FFT
    fft_freq = np.fft.fftfreq(n, d=1/fs)  # 頻率軸
    fft_magnitude = np.abs(fft_result) / n  # 振幅正規化

    # 只保留正頻率
    positive_freqs = fft_freq[:n//2]
    positive_magnitude = fft_magnitude[:n//2]

    if(-16 < (i*16-200) < 16):
        print("start 200")
    if(-16 < (i*16-500) < 16):
        print("finish 500")

    plt.figure(figsize=(1000,6))
    plt.stem(positive_freqs, positive_magnitude, basefmt=" ")
    plt.title("Frequency Domain (FFT)")
    plt.xlabel("Frequency (Hz)")
    plt.ylabel("Amplitude")
    plt.grid()
    plt.show()