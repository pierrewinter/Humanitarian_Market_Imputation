# Delivering Cash-Based Assistance to Syrian Communities :ambulance:

Humanitarian aid organizations are unable to provide accurate cash-based assistance in conflict regions. This is often due to the lack of pricing information for basic necessities found in local markets. How can we estimate missing prices of market goods in Syria such that families in need are given an adequate amount of aid?

### Project Overview :eyes:

This repository contains source code, supporting data, and a final written report of our data science solutions to this problem. They were developed in 8 weeks by a team of 4 data scientists at ETH Zurich. We collaborated with IMPACT Initiatives, an NGO which monitors and evaluates humanitarian interventions in order to support aid actors in assessing the efficacy of their programs. 

### Solutions :thumbsup:

Given a sparse dataset of market prices for different Syrian districts over a range of 2.5 years (of which only 40% of the price data is available), how can we estimate the missing 60% of the price data?

:fast_forward: ***Sequential Forward Fill*** - Python \
Pros: Easy to implement, requires little prior information \
Cons: Does not account for temporal or geographical fluctuations

:couple: ***Adapted K-Nearest Neighbors (KNN)*** - Python \
Pros: Good accuracy, easily adaptable \
Cons: Not well-defined near boundary values

:mouse: ***Multivariate Imputation by Chained Equations (MICE)*** - R \
Pros: High accuracy \
Cons: Assumes data is missing at random, difficult to interpret

### Useful Links
*  [IMPACT Initiatives Website](https://www.impact-initiatives.org)
*  [Hack4Good 2019](https://analytics-club.org/hack4good)
