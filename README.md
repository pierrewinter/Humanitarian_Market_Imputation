**Introduction:**  
This repository contains work done as part of the Fall 2019 Hack4Good Event at ETH Zurich in which our team developed a data science solution to a humanitarian problem in 8 weeks. Our team consisted of 4 ETH Zurich students and we collaborated with IMPACT Initiatives, an NGO which monitors and evaluates humanitarian and development interventions in order to support aid actors in assessing the efficiency and efficacy of their programmes. We present analytical methods which impute missing price values in a sparse dataset. This allows for more accurate and effective cash-based humanitarian programming around the world.

**Useful Links:**
*  [IMPACT Initiatives Website](https://www.impact-initiatives.org)
*  [Hack4Good 2019](https://analytics-club.org/hack4good)

**Folder Structure**

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

  ```conda env update -f environment.yml -n env_your_proj```

* activate the env  

  ```activate env_your_proj```
  
* in case of an issue clean all the cache in conda

   ```conda clean -a -y```

* delete the env to recreate it when too many changes are done  

  ```conda env remove -n env_your_proj```
