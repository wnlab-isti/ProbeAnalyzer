readcl_rev = "$Revision: 1.14 $";

fog.equiv = ...
[
 0x70b3d545F0FA 0x70b3d545F31E 0x70b3d545F221  		# C62 corridoio
 0x70b3d545F3B5 0x70b3d545F0FE 0x70b3d545F119  		# C64 corridoio
 0x70b3d545F1D4 0x70b3d545F0DE 0x70b3d545F397  		# C67 corridoio
 0x70b3d545F398 0x70b3d545F0CA 0x70b3d545F08A  		# C62
 0x70b3d545F1BA 0x70b3d545F22B 0x70b3d545F19E  		# C63
 0x70b3d545F088 0x70b3d545F31A 0x70b3d545F0AC  		# C64
 0x70b3d545F39D 0x70b3d545F285 0x70b3d545F188  		# C65
 0x70b3d545F3A8 0x70b3d545F419 0x70b3d545F084  		# C66
 0x70b3d545F421 0x70b3d545F1B8 0x70b3d545F278  		# C69
 0x70b3d545F228 0x70b3d545F1B4 0x70b3d545F327  		# C70a
 0x70b3d545F227 0	       0			# C72
 0x70b3d545F323 0x70b3d545F3E0 0x70b3d545F469  		# C74
];
fog.place = ...
{ "C62c" "C64c" "C67c" "C62" "C63" "C64" "C65" "C66" "C69" "C70a" "C72" "C74" };

## Windows 64-bit has a bug when parsing long hex literals
fog.equiv = ...
[  123917679587578   123917679588126   123917679587873
   123917679588277   123917679587582   123917679587609
   123917679587796   123917679587550   123917679588247
   123917679588248   123917679587530   123917679587466
   123917679587770   123917679587883   123917679587742
   123917679587464   123917679588122   123917679587500
   123917679588253   123917679587973   123917679587720
   123917679588264   123917679588377   123917679587460
   123917679588385   123917679587768   123917679587960
   123917679587880   123917679587764   123917679588135
   123917679587879                 0                 0
   123917679588131   123917679588320   123917679588457
];

## Read the data produced by the database dump function in db-data.sh
##    SELECT created, client_id, mac, dbm FROM mac
##    WHERE created >= '2016-03-04 00:00:00' AND created <= '2016-03-09 23:59:59'
##    GROUP by created, client_id, mac, dbm
##    ORDER by created, client_id, mac, dbm
function d = read_dump(dumpfile, fog)

  ## Dump data in a scalar struct
  d = struct("dates", [],			# date string  (pn)
	     "fogs", [],			# listening fog string  (pn)
	     "macs", [],			# detected mac string  (pn)
	     "pn", 0,				# number of probes
	     "sec", [],				# second starting at 1 (pn)
	     "fog", [],				# fog (pn)
	     "fogn", 0,				# number of unique fogs
	     "mac", [],				# mac (pn)
	     "macn", 0,				# number of unique macs
	     "rss", []				# rss (pn)
	    );

  ## Read the output of db-data.sh into four arrays
  [d.dates d.fogs d.macs d.rss] = ...
    textread(dumpfile,"%s%s%s%f",'delimiter',"\t",'headerlines',1,'whitespace',"");
  d.pn = length(d.dates);			# number of probes
  printf("Read %d probes\n", d.pn);

  ## Parse the dates into internal format, with 0 as the day of first entry
  ## This array has pn entries
  ## Do not use datenum with a string arg, as it calls datevec which is 30 times slower
  #[day sec] = datenum(dates,"yyyy-mm-dd HH:MM:SS");
  v = reshape(sscanf(strjoin(d.dates), "%d-%d-%d %d:%d:%d"), 6, [])';
  [day d.sec] = datenum(v(:,1),v(:,2),v(:,3),v(:,4),v(:,5),v(:,6));
  printf(" during %d days\n", floor(day(end)-day(1)));
  d.sec += 1 - d.sec(1);

  ## Make an array of fogsenses
  ## This array has pn entries
  fog_prefixs = "70b3d5";			# all fog MACs start like this
  d.fog = hex2dec(strcat(fog_prefixs, d.fogs));
  d.fogn = length(unique(d.fog));		# number of fogsenses
  printf(" from %d fogs\n", d.fogn);

  ## Make an array of probed MACs (removing the ":")
  ## This array has pn entries
  d.mac = hex2dec(char(d.macs)(:,[1 2 4 5 7 8 10 11 13 14 16 17]));
  d.macn = length(unique(d.mac));		# number of MACS seen
  printf(" observing %d unique macs.\n", d.macn);

endfunction


## Collapse equivalent mac and equivalent fog into the first one of
## equivalent fogs in the same place as indicated by EQUIV
## The collapsed dump CLD only contains the fields: pn sec fog fogn mac macn rss
function cld = collapse_dump (d, fog)

  ## All fogsenses must be listed int the equivalence table
  valid_equiv = fog.equiv(fog.equiv != 0);
  assert(numel(setdiff(d.fog, valid_equiv(:))) == 0,
	 "D contains fogsenses that are not in EQUIV");

  ## For all equivalent fogsenses, change the probing fog to the first
  ## equivalent one and change the probed mac to the first equivalent one,
  ## if the probed mac is one of the fogsenses.
  eqfog = d.fog;
  eqmac = d.mac;

  for rowidx = 1:rows(fog.equiv)

    ## Broadcast to matrix eq(d.pn,columns(fog.equiv)-1) of fog equivalents
    eq = (eqfog == fog.equiv(rowidx, 2:end));
    ## Set any fog in 2:end columns to fog in column 1 (collapsing)
    eqfog(any(eq, 2)) = fog.equiv(rowidx, 1);	# equivalent fog

    ## Broadcast to matrix eq(d.pn,columns(fog.equiv)-1) of mac equivalents
    eq = (eqmac == fog.equiv(rowidx, 2:end));
    ## Set any mac in 2:end columns to mac in column 1 (collapsing)
    eqmac(any(eq, 2)) = fog.equiv(rowidx, 1);	# equivalent mac

  endfor

  ## Keep only probes where the probing fog is different from the probed mac
  keepmask = (eqmac != eqfog);
  cld.pn = sum(keepmask);			# number of entries kept
  cld.sec = d.sec(keepmask);
  cld.fog = eqfog(keepmask);
  cld.fogn = length(unique(cld.fog));		# number of fogsenses
  assert(cld.fogn == rows(fog.equiv));		# internal check
  cld.mac = eqmac(keepmask);
  cld.macn = length(unique(cld.mac));		# number of MACS seen
  cld.rss = d.rss(keepmask);

endfunction


## Split dump D into two dump structures, an internal dump INTD relative
## to probes generated by fogs listed in FOG.equiv and an external dump
## EXTD relative to probes generated by external devices
## The split dumps only contains the fields: pn sec fog fogn mac macn rss
function [intd extd] = split_dump (d, fog)

  intmask = ismember(d.mac, fog.equiv);

  intd.pn = sum(intmask);
  intd.sec = d.sec(intmask);
  intd.fog = d.fog(intmask);
  intd.fogn = length(unique(intd.fog));		# number of fogsenses
  intd.mac = d.mac(intmask);
  intd.macn = length(unique(intd.mac));		# number of MACS seen
  assert(intd.fogn == intd.macn);		# probes are exchanged between fogsenses only
  intd.rss = d.rss(intmask);

  if (nargout > 1)
    extd.pn = sum(!intmask);
    extd.sec = d.sec(!intmask);
    extd.fog = d.fog(!intmask);
    extd.fogn = length(unique(extd.fog));	# number of fogsenses
    extd.mac = d.mac(!intmask);
    extd.macn = length(unique(extd.mac));	# number of MACS seen
    extd.rss = d.rss(!intmask);
  endif

endfunction


## Remove all fogs mentioned in Fog.equiv from dump D
## The returned dump only contains the fields: pn sec fog fogn mac macn rss
function fd = remove_fogs_from_dump (d, fog);

  fmask = ismember(d.mac, fog.equiv) | ismember(d.fog, fog.equiv);

  fd.pn = sum(!fmask);
  fd.sec = d.sec(!fmask);
  fd.fog = d.fog(!fmask);
  fd.fogn = length(unique(fd.fog));		# number of fogsenses
  fd.mac = d.mac(!fmask);
  fd.macn = length(unique(fd.mac));		# number of MACS seen
  fd.rss = d.rss(!fmask);

endfunction


## Find events, that is, probes sensed by more than one fogsense within
## HORIZON seconds
## Uses these fields of the dump D: pn sec fog mac rss
function events = find_events (d, horizon)

  ## Create a struct array
  used = false(d.pn, 1);
  events = struct("sec", [],		    # second starting at 1
		  "mac", [],		    # mac
		  "fog", {},		    # array of fog
		  "rss", {}		    # array of rss
		 );

  limit = d.pn;			# set this to a lower number for debugging
  events(limit).d.sec = [];	# excess allocation for efficiency
  eidx = 1;					# event index
  for pidx = 1:limit				# probe index
    if used(pidx); continue; endif
    events(eidx).d.sec = cursec = d.sec(pidx);
    events(eidx).mac = curmac = d.mac(pidx);
    hidx = pidx;				# horizon index
    while (hidx <= limit && d.sec(hidx) <= cursec + horizon)
      if (d.mac(hidx) == curmac)
	events(eidx).fog(end+1) = d.fog(hidx);
	events(eidx).rss(end+1) = d.rss(hidx);
	used(hidx) = true;
      endif
      hidx += 1;
    endwhile
    #events(eidx)
    eidx += 1;
  endfor
  events(eidx:limit) = [];			# remove empty elements
endfunction



## Split events into two event structures, INTEVENTS relative to probes
## generated by fogs and EXTEVENTS relative to probes generated by
## external devices
function [intevents extevents] = split_events (ev, fog)

  intmask = ismember(ev.mac, fog.equiv);
  intevents = ev(intmask);
  extevents = ev(!intmask);

endfunction


## Compute cross-fog rss values from an internal dump D
##
## Return a cell array CFRSS with one return arg, or make a plot with no return arg
## The second arg FOG is only necessary for printing the plot titles.
## The cell array has size NxN, where N is the number of different fogs.
## Each cell CFRSS(I,J) contains an array of RSS values from Tx I to Rx J.
## CFRSS(I,J) is empty where I==J.
function cfrss = cross_fog_rss (d, fog)
  fogtable = unique(d.fog);			# table of unique fogsense MACs
  fogn = d.fogn;
  assert(fogn == length(fogtable));		# internal consistency check

  ## The argument is an internal dump, so the fogtable is the same as
  ## the mactable: we do not check that, only that their length is equal
  assert(fogn == d.macn, "Argument is not an internal dump");
  fogtidx = lookup(fogtable, d.fog);		# fog indices in the table
  mactidx = lookup(fogtable, d.mac);		# mac indices in the table

  tmp = cell(fogn, fogn);
  for tx = 1:fogn
    for rx = 1:fogn
      if (tx != rx)
	tmp(tx, rx) = d.rss(mactidx == tx & fogtidx == rx);
      endif
    endfor
  endfor

  if (nargout > 0)
    cfrss = tmp;				# return value
    return;					# do not make plot
  endif

  if (nargin < 2)				# FOG argument is not there
     error("A FOG argument is needed to make a plot");
  endif

  assert(rows(fog.equiv) == length(fog.place)); # internal consistency check
  assert(fogn == length(fog.place),
	 "Number of FOG.PLACE labels different from fogs in dump D");

  for tx = 1:fogn
    for rx = 1:fogn
      if (tx != rx)
	subplot(fogn, fogn, rx + fogn*(tx-1)); # 'position', [startx starty width width]
	hist(tmp{tx,rx});
	title(sprintf("%s -> %s", fog.place{tx}, fog.place{rx}));
      endif
    endfor
  endfor

endfunction


## Compute cross-fog rss between collapsable fogs from an internal dump D
##
## Return a cell array CCFRSS.
## The cell array has size MxMxN, where [N M] = size(FOG.equiv)
## Each cell CFRSS(I,J,K) contains an array of RSS values from Tx I to Rx J
## taken from row K of the FOG.equiv table.
## CFRSS(I,J,K) is empty where I==J.
function ccfrss = collapsable_cross_fog_rss (d, fog)
  fogtable = unique(d.fog);			# table of unique fogsense MACs
  fogn = d.fogn;
  assert(fogn == length(fogtable));		# internal consistency check

  [n m] = size(fog.equiv);
  ccfrss = cell(m, m, n);
  for rowidx = 1:n
    ## Compute internal dump for equivalence group ROWIDX
    bfog = fog;					# fogs to remove
    bfog.equiv(rowidx,:) = [];
    bfog.place(rowidx) = [];
    fd = remove_fogs_from_dump(d, bfog);	# keep only group fogs
    gfog = fog;					# group fogs
    gfog.equiv = gfog.equiv(rowidx,:);
    gfog.place = gfog.place(rowidx);
    gintd = split_dump(fd, gfog);		# internal group dump
    gcfrss = cross_fog_rss(gintd);		# square cell array
    gm = rows(gcfrss);
    ccfrss(1:gm,1:gm,rowidx) = gcfrss;
  endfor

endfunction


## Print events, that is, probes sensed by more than one fogsense within
## HORIZON seconds
## Uses these fields of the dump D: pn dates fogs macs sec mac
function print_events (d, eventname, horizon)

  fid = fopen(sprintf("%s_%ds.txt", eventname, horizon), 'w');
  used = false(d.pn, 1);
  for idx = 1:d.pn
    if used(idx); continue; endif
    fprintf(fid, "%s,%s,", d.dates{idx}, d.macs{idx});
    observers = d.fogs(idx);
    start = d.sec(idx);
    sidx = idx;
    while (sidx < d.pn && d.sec(++sidx) <= start + horizon)
      if (d.mac(sidx) == d.mac(idx))
	observers(end+1) = d.fogs(sidx);
	used(sidx) = true;
      endif
    endwhile
    observers = sort(observers);
    count = 1;
    fprintf(fid, "[('%s'", observers{1});
    for sidx = 2:length(observers)
      if (observers{sidx} == observers{sidx-1})
	count += 1;
	continue
      else
	fprintf(fid, ", %d), ('%s'", count, observers{sidx});
	count = 1;
      endif
    endfor
    fprintf(fid, ", %d)]\n", count);
  endfor
  fclose(fid);
endfunction

#d = read_dump("c4wsense", fog);
## Number of probes sent by each fog

## Plot general activity of fogsenses
#fogno = lookup(unique(d.fog), d.fog);
#plot(d.sec, timefog, '.');

#timefog = sparse(d.sec, fogno, true);

#print_events(d, "events", 1);

#events1 = find_events(d, 1);
#events2 = find_events(d, 2);
#events3 = find_events(d, 3);

## Quantiles of No. of fogs detecting each event
#[quantile(cellfun('length',{events1.fog})', 0:0.05:1) quantile(cellfun('length',{events2.fog})', 0:0.05:1) quantile(cellfun('length',{events3.fog})', 0:0.05:1)]

## Quantiles of No. of collapsed fogs detecting each event
#cld = collapse_dump(d, fog);
#tic; clevents1=find_events(cld, 1); toc; clevents2 = find_events(cld,2); toc; clevents3 = find_events(cld,3); toc
#[quantile(cellfun('length',{clevents1.fog})', 0:0.05:1) quantile(cellfun('length',{clevents2.fog})', 0:0.05:1) quantile(cellfun('length',{clevents3.fog})', 0:0.05:1)]

## Quantiles of No. of collapsed fogs detecting each event
## divided into internal (only between fogs) and external probes
#[intevents1 extevents1] = split_events(events1, fog);
#[intevents2 extevents2] = split_events(events2, fog);
#[intevents3 extevents3] = split_events(events3, fog);
#[clintevents1 clextevents1] = split_events(clevents1, fog);
#[clintevents2 clextevents2] = split_events(clevents2, fog);
#[clintevents3 clextevents3] = split_events(clevents3, fog);
#[quantile(cellfun('length',{intevents1.fog})', 0:0.05:1) quantile(cellfun('length',{intevents2.fog})', 0:0.05:1) quantile(cellfun('length',{intevents3.fog})', 0:0.05:1) quantile(cellfun('length',{clintevents1.fog})', 0:0.05:1) quantile(cellfun('length',{clintevents2.fog})', 0:0.05:1) quantile(cellfun('length',{clintevents3.fog})', 0:0.05:1)]
#[quantile(cellfun('length',{extevents1.fog})', 0:0.05:1) quantile(cellfun('length',{extevents2.fog})', 0:0.05:1) quantile(cellfun('length',{extevents3.fog})', 0:0.05:1) quantile(cellfun('length',{clextevents1.fog})', 0:0.05:1) quantile(cellfun('length',{clextevents2.fog})', 0:0.05:1) quantile(cellfun('length',{clextevents3.fog})', 0:0.05:1)]

## Plot of cross-fog RSS values
#intcld = split_dump(cld, fog);
#h=figure; set (h, 'visible', 'off'); cross_fog_rss(intcld, fog); print("-S2560,2048","cross_rss.png")

## Plot starting from mysql dump
#readcl; d = read_dump("c4wsense", fog); cld = collapse_dump(d, fog); intcld = split_dump(cld, fog); cfrss = cross_fog_rss(intcld); cellfun('length', cfrss)

## Matrix of number of internal cross probes and their mean
#cfrss = cross_fog_rss(intcld, fog);
#cellfun('length', cfrss)
#cellfun('mean', cfrss)

## Matrices of cross probes internal to each group
#ccfrss = collapsable_cross_fog_rss (d, fog); cellfun('length', ccfrss)
#c = ccfrss;c(cellfun('isempty', c)) = -100; cellfun('std', c), cellfun('mean', c), cellfun('min', c)
#mean([cellfun('mean', c)](:,:,[1:10 12]), 3)



# Local Variables:
# fill-column: 115
# End:
