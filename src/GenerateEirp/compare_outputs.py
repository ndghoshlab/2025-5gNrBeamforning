import scipy.io as sio
import numpy as np
import os

names = [
    'Power_AzEl_PMI_Lin',
    'Power_AzEl_SSB_PMI_Lin',
    'Power_AzEl_SSB_Lin',
    'AF_AzEl_PMI_eField',
    'AF_AzEl_SSB_PMI_eField',
    'AF_ElAz_SSB_eField'
]

print("================ Comparing MAT Files ================")
for name in names:
    cpu_path = f'src/Save-Files/{name}_N1_4_N2_4_L_2_#SSB_1.mat'
    # Change the GPU path if you saved them in a different directory
    gpu_path = f'src/Save-Files/{name}_N1_4_N2_4_L_2_#SSB_1.mat' 
    
    if not os.path.exists(cpu_path):
        print(f"Skipping {name}: CPU file not found at {cpu_path}")
        continue
        
    cpu_data = sio.loadmat(cpu_path)['matrixData']
    gpu_data = sio.loadmat(gpu_path)['matrixData']
    
    # Check shapes
    if cpu_data.shape != gpu_data.shape:
        print(f"Mismatch in {name}: Shapes differ (CPU={cpu_data.shape}, GPU={gpu_data.shape})")
        continue
        
    # Check dtype
    if cpu_data.dtype != gpu_data.dtype:
        print(f"Mismatch in {name}: Dtypes differ (CPU={cpu_data.dtype}, GPU={gpu_data.dtype})")
        
    # Compute differences
    max_diff = np.max(np.abs(cpu_data - gpu_data))
    mean_diff = np.mean(np.abs(cpu_data - gpu_data))
    
    print(f"{name}:")
    print(f"  Shape:       {cpu_data.shape}")
    print(f"  Dtype:       {cpu_data.dtype}")
    print(f"  Max Diff:    {max_diff:.2e}")
    print(f"  Mean Diff:   {mean_diff:.2e}")
    if max_diff < 1e-10:
        print("  Status:      EXACT MATCH (within float64 tolerance)")
    elif max_diff < 1e-4:
        print("  Status:      CLOSE MATCH (minor numerical deviations)")
    else:
        print("  Status:      MISMATCH (large deviations)")
