Note, you will need to install the following prerequisites: 

**mGstat** - https://github.com/cultpenguin/mGstat

**fminsearchbnd** - https://www.mathworks.com/matlabcentral/fileexchange/8277-fminsearchbnd--fminsearchcon

**variogramfit** - https://www.mathworks.com/matlabcentral/fileexchange/25948-variogramfit

Run this code using the following commands:

1. First, process the points shapefile and produce vario_specs, out_points, and classes .mat files. 
```
fit_data('arc_files', 'dried_survey_joined.shp');
```
2. Next, process the data:
```
process_dried_data('arc_files', 'dried_survey_joined.shp', 'dried_contours_5_simple.shp', 'dried_trimble_mound_traces_polylines.shp', 'dried_reef_trace.shp');
```