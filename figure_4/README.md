Note, you will need to install the following prerequisites: 

**frenet** - https://www.mathworks.com/matlabcentral/fileexchange/11169-frenet

Run the following commands:

1. Create output directories:
```
mkdir('Trend_Plunge_Data');
mkdir('Trend_Plunge_Data/csv_files');
mkdir('Stat_Plots');
```

2. Load listing.mat:
```
load('listing.mat');
```

3. Process all measurements:
```
process_all_measurements(listing);
```
