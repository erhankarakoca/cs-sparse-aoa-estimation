function data = import_dac_data(fname)
%Read data from bin file and put into int16 data array
fin = fopen( fname, 'r');
data = fread( fin, Inf, 'integer*2');
fclose( fin);
data = int16( data);
end