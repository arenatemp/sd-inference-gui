@echo off

if not exist .\venv\ (
	echo INITIALIZING...
	mkdir venv
	python -m venv .\venv\
	call .\venv\Scripts\activate.bat
	start /wait /b pip install wheel
	start /wait /b pip install torch torchvision --index-url https://download.pytorch.org/whl/cu117
	start /wait /b pip install -r source\requirements_gui.txt
	start /wait /b pip install -r source\requirements_inference.txt
	start /wait /b pip install xformers
	start /wait /b pip install basicsr
	start /wait /b pip uninstall --yes opencv-python
	start /wait /b pip install opencv-python-headless
) else (
	call .\venv\Scripts\activate.bat
)

start python source\main.py
exit