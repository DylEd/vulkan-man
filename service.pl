#!/bin/perl

use strict;
use warnings;

use Mojolicious::Lite -signatures;

my $header = "/usr/share/doc/vulkan/man/html/";

get '/' => 'index';

get "/file/:file" => sub ($c) {
	my $file = $c->stash('file');
	my $filepath = $header.$file.'.html' if $file ne '';
	#my $filepath = $header.$file if $file ne '';

	#print '\n','\n',$filepath,'\n','\n';
	my $s;

	if(-e $filepath)
	{
		open FILE, '<', $filepath;
		$s = '';
		$s .= $_ while(<FILE>);
		close FILE;

		$c->render(text => $s);
	}
};

get "/search/:entry" => sub ($c) {
	my $entry = $c->stash('entry');

	my @paths = <"${header}${entry}*">;

	#print "\n","$header$entry","\n";

	$c->render(json => {paths => \@paths});
};

app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
	<style>
		* {
			margin: 0px;
			border: 0px;
			padding: 0px;
		}
		body {
			padding: 4px;
			overflow: hidden;
		}
		td {
			outline: 1px solid red;
			padding: 2px;
		}
		td#input {
			width: 90%;
			padding-right: 1em;
		}
		td#load button {
			width: 100%;
			padding: 2px;
			//outline: 3px solid gray;
		}
		input#path {
			border: 3px solid gray;
			width: 100%;
		}
		table#list {
			display: block;
			max-height: 30vh;
			overflow: scroll;
		}
		tr.list-item {
			background-color: rgb(29,29,29);
			width: 100%;
		}
		tr.list-item td {
			width: 100%;
		}
		iframe#frame {
			margin: 2%;
			margin-top: 3%;
			width: 96%;
			text-align: center;
			height: 90vh;
			outline: 3px solid gray;
		}
	</style>
	<script>
		let toid;

		function launch(s) {
			let ifr = document.getElementById("frame");

			if(s.substring(s.length - ".html".length) == ".html") {
				s = s.substring(0,s.length - ".html".length);
			}

			fetch(`file/${s}`)
				.then((response) => {
					if(!response.ok) {
						return null;
					}
					return response.blob();
				})
				.then((blob) => {
					ifr.src = URL.createObjectURL(blob);
				});
		}

		function load_page() {
			let tbx = document.getElementById("path");

			launch(tbx.value);
		}

		function clear() {
			let l = document.getElementById('list');

			while(l.firstChild) {
				l.removeChild(l.firstChild);
			}
		}

		function refresh() {
			if(toid) {
				clearTimeout(toid);
			}

			toid = setTimeout(clear,8e3);
		}

		function show_list(s) {
			let l = document.getElementById('list');

			fetch(`search/${s}`)
				.then((response) => {
					if(!response.ok) {
						return null;
					}
					clear();
					return response.json();
				})
				.then((json) => {
					for(const path of json.paths) {
						const listItem = document.createElement('tr');
						listItem.classList.add("list-item");

						const listCell = document.createElement('td');
						listCell.onclick = () => { launch(listCell.textContent);refresh(); };
						listCell.textContent = shorten(path);

						listItem.appendChild(listCell);
						l.appendChild(listItem);
					}
				});

			refresh();
		}

		//utility
		function shorten(s) {
			return s.substring(s.lastIndexOf('/') + 1);
		}
	</script>
</head>
<body>
	<table style="width: 40%; position: absolute;">
		<tr>
			<td id="input">
				<input id="path" type="text" onkeyup="show_list(this.value);"></input>
			</td>
			<td id="load">
				<button onclick="load_page();" >
					Load
				</button>
			</td>
		</tr>
		<tr>
			<td>
				<table id="list" style="width: 100%;" onmouseover="refresh();">
				</table>
			</td>
		</tr>
	</table>
	<iframe id="frame"></iframe>
</body>
</html>
