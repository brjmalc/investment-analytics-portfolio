# Run in VS Code

Open the repository root folder in VS Code. Install the Python and Jupyter extensions and create a virtual environment with Python 3.11 or later.

From a terminal at the repository root:

```sh
python -m venv .venv
# Activate .venv using the command appropriate to your operating system.
python -m pip install -r 02_Python_Portfolio_Study/requirements.txt
python 02_Python_Portfolio_Study/portfolio_study.py
```

Alternatively, open `portfolio_diversification.ipynb`, select the virtual environment as the notebook kernel, and run all cells. Use the repository root or the Python project directory as the working directory. The script and notebook find `data/` by looking upward from that directory.

Derived files are written to `02_Python_Portfolio_Study/outputs/`; shared input files are not overwritten. Saved notebook outputs reflect the original study run. Dependencies are version ranges, not an exact environment lock.
