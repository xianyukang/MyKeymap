#!/usr/bin/fish

cd config-front/; 
pnpm run serve &; 
cd ../; 
cd config-back/; 
python.exe api.py --server;
