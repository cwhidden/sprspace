/*
################################################################################
# matrix2pairs
################################################################################
#
# Convert an adjacency matrix graph to an edge list graph
# 
# Copyright 2014 Chris Whidden
# cwhidden@fhcrc.org
# May 2, 2014
# Version 1.0
# 
# This file is part of spr_grapher.
# 
# spr_grapher is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# spr_grapher is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with spr_grapher.  If not, see <http://www.gnu.org/licenses/>.
################################################################################
*/

#include <iostream>
#include <vector>
#include <string>
#include <cstdlib>
#include <sstream>

using namespace std;

#define IN_DELIM ','
#define OUT_DELIM '\t'

int main(int argc, char **argv) {

int k = 1;//INT_MAX;
if (argc > 1) {
	k = atoi(argv[1]);
}

vector<vector<int> > m = vector<vector<int> >();
string line = "";
int size = 0;
while(getline(cin, line)) {
	string token = "";
	m.push_back(vector<int>());
	for(int i = 0; i < line.size(); i++) {
		if (line[i] == IN_DELIM) {
			int num = -1;
			if (token != "") {
				num = atoi(token.c_str());
			}
			m[size].push_back(num);
			token = "";
		}
		else {
			token.push_back(line[i]);
		}
	}
	int num = -1;
	if (token != "") {
		num = atoi(token.c_str());
	}
	m[size].push_back(num);
	size++;
}


vector<bool> isolated = vector<bool>(m.size(), true);
cout << "source" << OUT_DELIM << "target" << OUT_DELIM << "distance" << endl;
for(int i = 0; i < m.size(); i++) {
	for(int j = i+1; j < m.size(); j++) {
		if (m[i][j] > 0 && m[i][j] <= k) {
			isolated[i] = false;
			isolated[j] = false;
			cout << i << OUT_DELIM << j << OUT_DELIM << m[i][j] << endl;
		}
	}
	if (isolated[i]) {
		cout << i << endl;
	}
}

}
