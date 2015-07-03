<cfobject component="distributor" name="dist">

<h1>Core Metrics Test</h1>
<cfdump var="#dist.getMetrics('coldfusion')#">

<h1>SeeFusion Metrics Test</h1>
<cfdump var="#dist.getMetrics('seefusion')#">
