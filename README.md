# Factors Contributing to COVID-19 Case Fatality Rate

*Code to the __Factors Contributing to Case Fatality__ project which won the __Best Overall Award__ at the __[IC2S2](https://www.ic2s2.org/) 2022 Datathon__*

## Results

Visualizations: [1](https://public.tableau.com/app/profile/hong.qu5598/viz/Datathon_team_6/Dashboard1?publish=yes), [2](https://public.tableau.com/app/profile/hong.qu5598/viz/datathon_all_dates/Sheet3?publish=yes)

Recorded presentation: *coming soon*

Extended presentation at award ceremony: [slides](https://docs.google.com/presentation/d/1apf2QBto7melikp6LnR3Md45E8epsO56awjHlphVYa4/edit#slide=id.g136c755949c_0_25)

## Code

Data can be downloaded from [KnowledgeLab/IC2S2_Datathon](https://github.com/KnowledgeLab/IC2S2_Datathon) and put in `data/`

Scripts

- `convert.py` converts the provided `msa_dict.pkl` file to json

- `outbreaks.r` detects COVID-19 outbreaks from NYT data on daily cumulative cases
    - filter for days in any MSA in which cases reached >= 10000
    - calculate cases between 30 days before and 60 days after the event and deaths within the next 90 days
    - days that are part of the same outbreak could be manually filtered out from the script output to produce the final outbreak events in `data/outbreaks_events_10000_cases.csv`
