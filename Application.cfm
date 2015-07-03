<!--- This needs to be in both the Aggregator/Collector's dir, as well as the Agent's.
      Otherwise your session count will keep going up with each ping for data --->
<cfapplication name="FlexMon" sessionmanagement="No" setclientcookies="No">