---
layout: page
title: Overview
id: overview
description: Taxonomy and status of accession numbers
---

<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.12.1/css/jquery.dataTables.css">
<script src="https://code.jquery.com/jquery-3.6.0.min.js" integrity="sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=" crossorigin="anonymous"></script>
<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/1.12.1/js/jquery.dataTables.js"></script>

<script type="text/javascript">
$(document).ready( function () {
	$('#ovtable').DataTable({searchDelay: 350});
	$('#ovtable').show();
	$('#warning').hide();
	$('.loader').hide();
} );
</script>

<style>
.status-present {
	background-color: lightgreen
}
.status-absent {
	background-color: orange
}
.status-modified {
	background-color: red
}

.loader {
  border: 16px solid #f3f3f3; /* Light grey */
  border-top: 16px solid #3498db; /* Blue */
  border-radius: 50%;
  width: 120px;
  height: 120px;
  animation: spin 2s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>

## Overview Table

<h3 id="warning">⚠️ A large table is loading in the background, this might take a minute ⚠️ </h3>
<!-- Loader via css as described in https://www.w3schools.com/howto/howto_css_loader.asp -->
<div class="loader"></div>

<table id="ovtable" style="display: none">
<thead>
<tr>
<th> Accession </th><th> Taxonomy </th><th> Status </th>
</tr>
</thead>
<tbody>
{%- for entry in site.data.headers_comparison %}
<tr>
<td> {{ entry.Accession }} </td><td> {{ entry.Taxonomy }} </td><td class="status-{{ entry.Status }}"> {{ entry.Status }} </td>
</tr>
{%- endfor %}
</tbody>
</table>


