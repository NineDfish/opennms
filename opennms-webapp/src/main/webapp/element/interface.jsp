<%--

//
// This file is part of the OpenNMS(R) Application.
//
// OpenNMS(R) is Copyright (C) 2002-2005 The OpenNMS Group, Inc.  All rights reserved.
// OpenNMS(R) is a derivative work, containing both original code, included code and modified
// code that was published under the GNU General Public License. Copyrights for modified 
// and included code are below.
//
// OpenNMS(R) is a registered trademark of The OpenNMS Group, Inc.
//
// Modifications:
//
// 2005 Sep 30: Hacked up to use CSS for layout. -- DJ Gregor
// 2003 Oct 07: Corrected issue with selecting non-IP interface SNMP data.
// 2003 Sep 25: Fixed SNMP Performance link issue.
// 2003 Feb 07: Fixed URLEncoder issues.
// 2003 Feb 01: Added response time link (Bug #684) and HTTP link (Bug #469).
// 2002 Nov 26: Fixed breadcrumbs issue.
// 
// Original code base Copyright (C) 1999-2001 Oculan Corp.  All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
//
// For more information contact:
//      OpenNMS Licensing       <license@opennms.org>
//      http://www.opennms.org/
//      http://www.opennms.com///

--%>

<%@page language="java"
	contentType="text/html"
	session="true"
	import="org.opennms.netmgt.config.PollerConfigFactory,
		org.opennms.netmgt.config.PollerConfig,
		org.opennms.web.element.*,
		java.util.*,
                org.opennms.web.authenticate.Authentication,
		org.opennms.web.event.*,
		org.opennms.web.performance.*,
		org.opennms.netmgt.utils.IfLabel,
		org.opennms.web.response.*
		"
%>

<%!
    protected int telnetServiceId;
    protected int httpServiceId;
    protected PerformanceModel perfModel;
    protected ResponseTimeModel rtModel;
    
    public void init() throws ServletException {
        try {
            this.telnetServiceId = NetworkElementFactory.getServiceIdFromName("Telnet");            
        }
        catch( Exception e ) {
            throw new ServletException( "Could not determine the Telnet service ID", e );
        }
        
        try {
            this.perfModel = new PerformanceModel( org.opennms.core.resource.Vault.getHomeDir() );
        }
        catch( Exception e ) {
            throw new ServletException( "Could not initialize the PerformanceModel", e );
        }        

        try {
            this.httpServiceId = NetworkElementFactory.getServiceIdFromName("HTTP");
        }
        catch( Exception e ) {
            throw new ServletException( "Could not determine the HTTP service ID", e );
        }

        try {
            this.perfModel = new PerformanceModel( org.opennms.core.resource.Vault.getHomeDir() );
        }
        catch( Exception e ) {
            throw new ServletException( "Could not initialize the PerformanceModel", e );
        }

        try {
            this.rtModel = new ResponseTimeModel( org.opennms.core.resource.Vault.getHomeDir() );
        }
        catch( Exception e ) {
            throw new ServletException( "Could not initialize the ResponseTimeModel", e );
        }

    }
%>

<%
    String nodeIdString = request.getParameter( "node" );
    String ipAddr = request.getParameter( "intf" );
    String ifindexString = request.getParameter( "ifindex" );
    
    if( nodeIdString == null ) {
        throw new org.opennms.web.MissingParameterException( "node", new String[] { "node", "intf", "ifindex?"} );
    }

    if( ipAddr == null ) {
        throw new org.opennms.web.MissingParameterException( "intf", new String[] { "node", "intf", "ifindex?" } );
    }

    int nodeId = -1;
    int ifindex = -1;
    
    try {
        nodeId = Integer.parseInt( nodeIdString );
        if (ifindexString != null) 
            ifindex = Integer.parseInt( ifindexString );
    }
    catch( NumberFormatException e ) {
        //throw new WrongParameterDataTypeException
        throw new ServletException( "Wrong data type, should be integer", e );
    }

    Interface intf_db = null;
    
    //see if we know the ifindex
    if (ifindexString == null) {
        intf_db = NetworkElementFactory.getInterface( nodeId, ipAddr );
    }
    else {
        intf_db = NetworkElementFactory.getInterface( nodeId, ipAddr, ifindex );
    }
    
    if( intf_db == null ) {
        //handle this WAY better, very awful
        throw new ServletException( "No such interface in the database" );
    }

    Service[] services = NetworkElementFactory.getServicesOnInterface( nodeId, ipAddr );
    if( services == null ) {
        services = new Service[0];
    }

    String eventUrl = "event/list?filter=node%3D" + nodeId + "&filter=interface%3D" + ipAddr;
    
    String telnetIp = null;
    Service telnetService = NetworkElementFactory.getService(nodeId, ipAddr, this.telnetServiceId);
    
    if( telnetService != null  ) {
        telnetIp = ipAddr;
    }    

    String httpIp = null;
    Service httpService = NetworkElementFactory.getService(nodeId, ipAddr, this.httpServiceId);

    if( httpService != null  ) {
        httpIp = ipAddr;
    }
    PollerConfigFactory.init();
    PollerConfig pollerCfgFactory = PollerConfigFactory.getInstance();
    pollerCfgFactory.rebuildPackageIpListMap();

%>

<% String nodeBreadCrumb = "<a href='element/node.jsp?node=" + nodeId  + "'>Node</a>"; %>
<jsp:include page="/includes/header.jsp" flush="false" >
  <jsp:param name="title" value="Interface" />
  <jsp:param name="headTitle" value="<%= ipAddr %>" />
  <jsp:param name="headTitle" value="Interface" />
  <jsp:param name="breadcrumb" value="<a href='element/index.jsp'>Search</a>" />
  <jsp:param name="breadcrumb" value="<%= nodeBreadCrumb %>" />
  <jsp:param name="breadcrumb" value="Interface" />
</jsp:include>

<% if (request.isUserInRole("OpenNMS Administrator")) { %>

<script type="text/javascript" >
function doDelete() {
     if (confirm("Are you sure you want to proceed? This action will permanently delete this interface and cannot be undone."))
     {
         document.forms["delete"].submit();
     }
     return false;
}
</script>
<% } %>


      <h2>Interface: <%=intf_db.getIpAddress()%> <%=intf_db.getIpAddress().equals(intf_db.getHostname()) ? "" : "(" + intf_db.getHostname() + ")"%></h2>

        <% if (request.isUserInRole("OpenNMS Administrator")) { %>
      <form method="post" name="delete" action="admin/deleteInterface">
      <input type="hidden" name="node" value="<%=nodeId%>"/>
      <input type="hidden" name="ifindex" value="<%=(ifindexString == null ? "" : ifindexString)%>"/>
      <input type="hidden" name="intf" value="<%=ipAddr%>"/>
      <% } %>

      <div id="linkbar">
      <ul>
	<li>
        <a href="<%=eventUrl%>">View Events</a>
	</li>

        <% if( telnetIp != null ) { %>
	  <li>
          <a href="telnet://<%=telnetIp%>">Telnet</a>
	  </li>
        <% } %>
        
        <% if( httpIp != null ) { %>
	  <li>
          <a href="http://<%=httpIp%>">HTTP</a>
	  </li>
        <% } %>
        
        <% if(this.rtModel.isQueryableInterface(ipAddr)) { %>
	  <li>
          <a href="response/addReportsToUrl?node=<%=nodeId%>&intf=<%=ipAddr%>&relativetime=lastday">Response Time</a>
	  </li>
        <% } %>

        <% if(hasSNMPData(intf_db) && ifindexString == null) { %>
              <% String ifLabel = IfLabel.getIfLabel(nodeId, ipAddr); %>
          <% if(ifLabel != null && this.perfModel.isQueryableInterface(nodeId, ifLabel)) { %>
	    <li>
            <a href="performance/addReportsToUrl?node=<%=nodeId%>&intf=<%=ifLabel%>&relativetime=lastday">SNMP Performance</a>
	    </li>
          <% } %>
        <% } %>
        <% if(hasSNMPData(intf_db) && ifindexString != null) { %>
              <% String ifLabel = IfLabel.getIfLabelfromIfIndex(nodeId, ipAddr, ifindexString); %>
          <% if(ifLabel != null && this.perfModel.isQueryableInterface(nodeId, ifLabel)) { %>
	    <li>
            <a href="performance/addReportsToUrl?node=<%=nodeId%>&intf=<%=ifLabel%>&relativetime=lastday">SNMP Performance</a>
	    </li>
          <% } %>
        <% } %>
        
        <% if (request.isUserInRole("OpenNMS Administrator")) { %>
	 <li>
         <a href="admin/deleteInterface" onClick="return doDelete()">Delete</a>
	 </li>
         <% } %>
         
        <% if( !(request.isUserInRole( Authentication.READONLY_ROLE ))) { %>
	  <li>
            <a href="element/rescan.jsp?node=<%=nodeId%>&ipaddr=<%=ipAddr%>">Rescan</a>      
          </li>
         <% } %>

        <% if (request.isUserInRole("OpenNMS Administrator") && hasSNMPData(intf_db) && "P".equals(intf_db.getIsSnmpPrimary())) { %>
	 <li>
         <a href="admin/updateSnmp.jsp?node=<%=nodeId%>&ipaddr=<%=ipAddr%>">Update SNMP</a>
	 </li>
         <% } %>
      </ul>
      </div>

      <% if (request.isUserInRole("OpenNMS Administrator")) { %>
      </form>
      <% } %>

	<div id="contentleft">

            <!-- general info box -->
	    <table class="standardfirst">
              <tr>
                <td class="standardheader" colspan="2">General</td>
              </tr>
              <tr>
                <td class="standard">Node</td> 
                <td class="standard"><a href="element/node.jsp?node=<%=intf_db.getNodeId()%>"><%=NetworkElementFactory.getNodeLabel(intf_db.getNodeId())%></a></td>
              </tr>
              <tr> 
                <td class="standard">Polling Status</td>
                <td class="standard"><%=ElementUtil.getInterfaceStatusString(intf_db)%></td>
              </tr>
              <% if(ElementUtil.getInterfaceStatusString(intf_db).equals("Managed") && request.isUserInRole("OpenNMS Administrator")) {
                  List inPkgs = pollerCfgFactory.getAllPackageMatches(ipAddr);
                  Iterator pkgiter = inPkgs.iterator();
                  while (pkgiter.hasNext()) { %>
                      <tr>
                          <td class="standard">Polling Package</td>
                          <td class="standard"><%= (String) pkgiter.next()%></td>
                      </tr>
                  <% } %>
              <% } %>
              <tr>
                <td class="standard">Interface Index</td> 
                <td class="standard">
                  <% int ifIndex = intf_db.getIfIndex(); %>
                  <% if( ifIndex > 0 ) {  %>
                    <%=ifIndex%>
                  <% } else { %>
                    &nbsp;
                  <% } %>
                </td>
              </tr>
              <tr> 
                <td class="standard">Last Service Scan</td>
                <td class="standard"><%=intf_db.getLastCapsdPoll()%></td>
              </tr>
              <tr>
                <td class="standard">Physical Address</td>        
                <td class="standard">
                  <% String macAddr = intf_db.getPhysicalAddress(); %>
                  <% if( macAddr != null && macAddr.trim().length() > 0 ) { %>
                    <%=macAddr%>
                  <% } else { %>
                    &nbsp;
                  <% } %>
                </td>
              </tr>
            </table>
            
            <!-- SNMP box, if info available -->
            <% if( hasSNMPData(intf_db) ) { %>
		  <table class="standard">
		    <tr>
                      <td class="standardheader" colspan="2">SNMP Attributes</td>
                    </tr>
                    <tr> 
                      <td class="standard">Subnet Mask</td>
                      <td class="standard">
                        <%=(intf_db.getSnmpIpAdEntNetMask() == null) ? "&nbsp;" : intf_db.getSnmpIpAdEntNetMask()%>                                    
                      </td>
                    </tr>
                    <tr>
                      <td class="standard">Interface Type</td>
                      <td class="standard"><%=IFTYPES[intf_db.getSnmpIfType()]%></td>
                    </tr>
                    <tr> 
                      <td class="standard">Status (Adm/Op)</td>
                      <td class="standard">
                        <% if( intf_db.getSnmpIfAdminStatus() < 1 || intf_db.getSnmpIfOperStatus() < 1 ) { %>
                          &nbsp;
                        <% } else { %>
                          <%=OPER_ADMIN_STATUS[intf_db.getSnmpIfAdminStatus()]%>/<%=OPER_ADMIN_STATUS[intf_db.getSnmpIfOperStatus()]%>
                        <% } %>
                      </td>
                    </tr>
                    <tr>
                      <td class="standard">Speed</td>        
                      <td class="standard"><%=(intf_db.getSnmpIfSpeed() > 0) ? String.valueOf(intf_db.getSnmpIfSpeed()) : "&nbsp;"%></td>
                    </tr>
                    <tr> 
                      <td class="standard">Description</td>
                      <td class="standard"><%=(intf_db.getSnmpIfDescription() == null) ? "&nbsp;" : intf_db.getSnmpIfDescription()%></td>
                    </tr>
                    <tr>
                      <td class="standard">Alias</td>
                      <td class="standard"><%=(intf_db.getSnmpIfAlias() == null) ? "&nbsp;" : intf_db.getSnmpIfAlias()%></td>
                    </tr>

                  </table>
            <% } %>

            <!-- services box -->
	    <table class="standard">
	      <tr>
	        <td class="standardheader">Services</td>
              </tr>
              <% for( int i=0; i < services.length; i++ ) { %>
                <tr>
                  <td class="standard"><a href="element/service.jsp?node=<%=services[i].getNodeId()%>&intf=<%=services[i].getIpAddress()%>&service=<%=services[i].getServiceId()%>"><%=services[i].getServiceName()%></a></td>
                </tr>
              <% } %>
            </table>

            <!-- Availability box -->
            <jsp:include page="/includes/interfaceAvailability-box.jsp" flush="false" />

</div>
       

<div id="contentright">

            <!-- interface desktop information box -->
          
            <!-- events list box -->
            <% String eventHeader = "<a href='" + eventUrl + "'>Recent Events</a>"; %>
            <% String moreEventsUrl = eventUrl; %>
            <jsp:include page="/includes/eventlist.jsp" flush="false" >
              <jsp:param name="node" value="<%=nodeId%>" />
              <jsp:param name="ipAddr" value="<%=ipAddr%>" />
              <jsp:param name="throttle" value="5" />
              <jsp:param name="header" value="<%=eventHeader%>" />
              <jsp:param name="moreUrl" value="<%=moreEventsUrl%>" />
            </jsp:include>
            
            <!-- Recent outages box -->
            <jsp:include page="/includes/interfaceOutages-box.jsp" flush="false" />
            


</div> <!-- id="contentright" -->

<jsp:include page="/includes/footer.jsp" flush="false" />


<%!
  //from the book _SNMP, SNMPv2, SNMPv3, and RMON 1 and 2_  (3rd Ed)
  //by William Stallings, pages 128-129
  public static final String[] IFTYPES = new String[] {
    "&nbsp;",                     //0 (not supported)
    "other",                    //1
    "regular1822",              //2
    "hdh1822",                  //3
    "ddn-x25",                  //4
    "rfc877-x25",               //5
    "ethernetCsmacd",           //6
    "iso88023Csmacd",           //7
    "iso88024TokenBus",         //8
    "iso88025TokenRing",        //9
    "iso88026Man",              //10
    "starLan",                  //11
    "proteon-10Mbit",           //12
    "proteon-80Mbit",           //13
    "hyperchannel",             //14
    "fddi",                     //15
    "lapb",                     //16
    "sdlc",                     //17
    "ds1",                      //18
    "e1",                       //19
    "basicISDN",                //20
    "primaryISDN",              //21
    "propPointToPointSerial",   //22
    "ppp",                      //23
    "softwareLoopback",         //24
    "eon",                      //25
    "ethernet-3Mbit",           //26
    "nsip",                     //27
    "slip",                     //28
    "ultra",                    //29
    "ds3",                      //30
    "sip",                      //31
    "frame-relay",              //32
    "rs232",                    //33
    "para",                     //34
    "arcnet",                   //35
    "arcnetPlus",               //36
    "atm",                      //37
    "miox25",                   //38
    "sonet",                    //39
    "x25ple",                   //40
    "is0880211c",               //41
    "localTalk",                //42
    "smdsDxi",                  //43
    "frameRelayService",        //44
    "v35",                      //45
    "hssi",                     //46
    "hippi",                    //47
    "modem",                    //48
    "aa15",                     //49
    "sonetPath",                //50
    "sonetVT",                  //51
    "smdsIcip",                 //52
    "propVirtual",              //53
    "propMultiplexor",          //54
    "ieee80212",                //55
    "fibreChannel",             //56
    "hippiInterface",           //57
    "frameRelayInterconnect",   //58
    "aflane8023",               //59
    "aflane8025",               //60
    "cctEmul",                  //61
    "fastEther",                //62
    "isdn",                     //63
    "v11",                      //64
    "v36",                      //65
    "g703at64k",                //66
    "g703at2mb",                //67
    "qllc",                     //68
    "fastEtherFX",              //69
    "channel",                  //70
    "ieee80211",                //71
    "ibm370parChan",            //72
    "escon",                    //73
    "dlsw",                     //74
    "isdns",                    //75
    "isdnu",                    //76
    "lapd",                     //77
    "ipSwitch",                 //78
    "rsrb",                     //79
    "atmLogical",               //80
    "ds0",                      //81
    "ds0Bundle",                //82
    "bsc",                      //83
    "async",                    //84
    "cnr",                      //85
    "iso88025Dtr",              //86
    "eplrs",                    //87
    "arap",                     //88
    "propCnls",                 //89
    "hostPad",                  //90
    "termPad",                  //91
    "frameRelayMPI",            //92
    "x213",                     //93
    "adsl",                     //94
    "radsl",                    //95
    "sdsl",                     //96
    "vdsl",                     //97
    "iso88025CRFPInt",          //98
    "myrinet",                  //99
    "voiceEM",                  //100
    "voiceFXO",                 //101
    "voiceFXS",                 //102
    "voiceEncap",               //103
    "voiceOverIp",              //104
    "atmDxi",                   //105
    "atmFuni",                  //106
    "atmIma",                   //107
    "pppMultilinkBundle",       //108
    "ipOverCdlc",               //109
    "ipOverClaw",               //110
    "stackToStack",             //111
    "virtualIpAddress",         //112
    "mpc",                      //113
    "ipOverAtm",                //114
    "iso88025Fiber",            //115
    "tdlc",                     //116
    "gigabitEthernet",          //117
    "hdlc",                     //118
    "lapf",                     //119
    "v37",                      //120
    "x25mlp",                   //121
    "x25huntGroup",             //122
    "trasnpHdlc",               //123
    "interleave",               //124
    "fast",                     //125
    "ip",                       //126
    "docsCableMaclayer",        //127
    "docsCableDownstream",      //128
    "docsCableUpstream",        //129
    "a12MppSwitch",             //130
    "tunnel",                   //131
    "coffee",                   //132
    "ces",                      //133
    "atmSubInterface",          //134
    "l2vlan",                   //135
    "l3ipvlan",                 //136
    "l3ipxvlan",                //137
    "digitalPowerline",         //138
    "mediaMailOverIp",          //139
    "dtm",                      //140
    "dcn",                      //141
    "ipForward",                //142
    "msdsl",                    //143
    "ieee1394",                 //144
    "if-gsn",                   //145
    "dvbRccMacLayer",           //146
    "dvbRccDownstream",         //147
    "dvbRccUpstream",           //148
    "atmVirtual",               //149
    "mplsTunnel",               //150
    "srp",                      //151
    "voiceOverAtm",             //152
    "voiceOverFrameRelay",      //153
    "idsl",                     //154
    "compositeLink",            //155
    "ss7SigLink",               //156
    "propWirelessP2P",          //157
    "frForward",                //158
    "rfc1483",                  //159
    "usb",                      //160
    "ieee8023adLag",            //161
    "bgppolicyaccounting",      //162
    "frf16MfrBundle",           //163
    "h323Gatekeeper",           //164
    "h323Proxy",                //165
    "mpls",                     //166
    "mfSigLink",                //167
    "hdsl2",                    //168
    "shdsl",                    //169
    "ds1FDL",                   //170
    "pos",                      //171
    "dvbAsiIn",                 //172
    "dvbAsiOut",                //173
    "plc",                      //174
    "nfas",                     //175
    "tr008",                    //176
    "gr303RDT",                 //177
    "gr303IDT",                 //178
    "isup",                     //179
    "propDocsWirelessMaclayer",      //180
    "propDocsWirelessDownstream",    //181
    "propDocsWirelessUpstream",      //182
    "hiperlan2",                //183
    "propBWAp2Mp",              //184
    "sonetOverheadChannel",     //185
    "digitalWrapperOverheadChannel", //186
    "aal2",                     //187
    "radioMAC",                 //188
    "atmRadio",                 //189
    "imt",                      //190
    "mvl",                      //191
    "reachDSL",                 //192
    "frDlciEndPt",              //193
    "atmVciEndPt",              //194
    "opticalChannel",           //195
    "opticalTransport"          //196
  };


  public static final String[] OPER_ADMIN_STATUS = new String[] {
    "&nbsp;",          //0 (not supported)
    "Up",              //1
    "Down",            //2
    "Testing",         //3
    "Unknown",         //4
    "Dormant",         //5
    "NotPresent",      //6
    "LowerLayerDown"   //7
  };

  
  private boolean hasSNMPData(Interface intf_db)
  {
      if (intf_db.getSnmpIpAdEntNetMask() != null)
          return true;
      
      if (intf_db.getSnmpIfType() > 0)
          return true;
      
      if (intf_db.getSnmpIfSpeed() > 0)
          return true;
          
      if (intf_db.getSnmpIfDescription() != null)
          return true;
          
      if (intf_db.getSnmpIfAdminStatus() > 0)
          return true;
      
      if (intf_db.getSnmpIfOperStatus() > 0)
          return true;

      if (intf_db.getSnmpIfAlias() != null)
          return true;
      
      return false;
  }
  
%>
