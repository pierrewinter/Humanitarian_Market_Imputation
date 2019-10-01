**Introduction:**  
Welcome to the GitLab Repo for the HS19 edition of Hack4Good.  
The repo will be made public and licensed under your name with an open-source 
license after the end of the program, such that other NGOs and the Humanitarian
sector may benefit from your great work! That being said, enjoy the ride and use 
your skills to make this world a better place! 

Your Hack4Good team (:


**Useful Links:**
*  [H4G HS19 Edition Google Drive](https://drive.google.com/drive/u/0/folders/0ABpSrE_j2_nHUk9PVA)
*  [Internal Displacement Monitoring Centre Website](http://www.internal-displacement.org)

**Workshop Dates:**

| Event | Date | Location |
| ------ | ------ | ------ |
| Kick-off |  02.10.19 (Wed) , 17:30 - 21:30| SPH |
| Hackday 1 |  05.10.19 (Sat) , 09:00 - 18:00| SPH |
| Workshop 1: Agile Workshop |  09.10.19 (Wed) , 17:30 - 21:30| SPH |
| Workshop 2: Feedback Workshop |  16.10.19 (Wed) , 17:30 - 21:30| SPH |
| Workshop 3: Impact Workshop |  23.10.19 (Wed) , 17:30 - 21:30| SPH |
| Workshop 4: Pitch Workshop |  30.10.19 (Wed) , 17:30 - 21:30| SPH |
| Hackday 2 |  10.11.19 (Sat) , 09:00 - 18:00| SPH |
| Workshop 5: Dry-run Workshop |  13.11.19 (Wed) , 17:30 - 21:30| SPH |
| Final Event |  20.11.19 (Wed) , 17:30 - 21:30| SPH |

**Folder Structure**

We have already created a folder structure that should help you starting right away. It should be seen as a guideline and shall help us
navigate through the code more easily. All present code is exemplatory and you don't have to use any of it. Feel free to delete the existing notebooks as well as the code in src.


```
├── LICENSE
│
│
├── README.md                <- The top-level README for developers using this project
│
├── environment.yml          <- Python environment
│                               
│
├── data
│   ├── processed            <- The final, canonical data sets for modeling.
│   └── raw                  <- The original, immutable data dump.
│
│
├── misc                     <- miscellaneous
│
│
├── notebooks                <- Jupyter notebooks. Every developper has its own folder for exploratory
│   ├── name                    notebooks. Usually every model has its own notebook where models are
│   │   └── exploration.ipynb   tested and optimized. (The present notebooks can be deleted as they are                                      empty and just serve to illustrate the folder structure.)
│   └── model
│       └── model_exploration.ipynb <- different optimized models can be compared here if preferred    
│
│
├── reports                   <- Generated analysis as HTML, PDF, LaTeX, etc.
│   └── figures               <- Generated graphics and figures to be used in reporting
│
│
├── results
│   ├── outputs
│   └── models               <- Trained and serialized models, model predictions, or model summaries
│                               (if present)
│
├── scores                   <- Cross validation scores are saved here. (Automatically generated)
│   └── model_name           <- every model has its own folder. 
│
├── src                      <- Source code of this project. All final code comes here (Notebooks are thought for exploration)
│   ├── __init__.py          <- Makes src a Python module
│   ├── main.py              <- main file, that can be called.
│   │
│   │
│   └── utils                <- Scripts to create exploratory and results oriented visualizations
│       └── exploration.py      / functions to evaluate models
│       └── evaluation.py       There is an exemplary implementation of these function in the sample notebook and they should be seen
                                as a help if you wish to use them. You can completely ignore or delete both files.
```

**How to use a python environment**

The purpose of virtual environments is to ensure that every developper has an identical python installation such that conflicts due to different versions can be minimized.

**Instruction**

Open a console and move to the folder where your environment file is stored.

* create a python env based on a list of packages from environment.yml

  ```conda env create -f environment.yml -n env_your_proj```

* update a python env based on a list of packages from environment.yml

  ```conda env update -f environment.yml -n env__your_proj```

* activate the env  

  ```activate env_your_proj```
  
* in case of an issue clean all the cache in conda

   ```conda clean -a -y```

* delete the env to recreate it when too many changes are done  

  ```conda env remove -n env_your_proj```
