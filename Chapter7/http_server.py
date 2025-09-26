# Import the built-in HTTP server class for handling web requests
from http.server import HTTPServer, SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

# Import argparse for command-line argument parsing
import argparse
# Import standard libraries for handling JSON
import json
import threading

# Import IBM DB2 connection tools and itoolkit
import ibm_db
from itoolkit import *
from itoolkit.transport import DirectTransport

# Create a transport object that allows the toolkit to talk to IBM i using SQL
itransport = DirectTransport()
print("Starting HTTP Server... Please wait...")

# -----------------------------------------
# DEFINE HTTP REQUEST HANDLER CLASS
# -----------------------------------------

class RPGHTTPRequestHandler(SimpleHTTPRequestHandler):
    LIBRARY = 'RTHOMPSON1'  # default; will be overridden

    """
    Custom HTTP handler that serves static files and also handles /api GET and POST requests,
    calling an RPGLE program using itoolkit.
    """

    def call_rpg(self, method, req_data):
    
        """
        Call the RPGLE program 'WEBSERV' in library,
        passing in the HTTP method and request data as parameters,
        and returning the RPG response.

        Parameters:
            method (str): 'GET' or 'POST'
            req_data (str): JSON or text from the HTTP request

        Returns:
            str: response string returned from RPG program
        """
    
        # Initialize the toolkit object
        itool = iToolKit()

        # Add the library to the library list so the program can be found
        itool.add(iCmd('addlible', f'ADDLIBLE {self.LIBRARY}'))

        # Add the RPG program call with 3 parameters:
        # - method: 10-character input
        # - request: 32000-character input
        # - response: 32000-character output (blank string placeholder)
        itool.add(iPgm('pgmcall', 'WEBHNDLR')
                  .addParm(iData('method', '10a', method))
                  .addParm(iData('request', '32000a', req_data))
                  .addParm(iData('response', '32000a', ' '))
                 )

        # Execute the RPG call
        itool.call(itransport)

        # Retrieve the output from the RPG program
        result = itool.dict_out('pgmcall')

        # Return the response value or fallback if missing
        return result.get('response', 'No response')

    # Handle HTTP GET requests to /api by calling the RPG program
    def do_GET(self):
        if self.path.startswith('/api'):

            # Parse query string into JSON string
            query = urlparse(self.path).query
            query_dict = parse_qs(query)

            # Check for shutdown command
            if query_dict.get('action', [''])[0].upper() == 'SHUTDOWN':
                print("⚠️  Shutdown requested via HTTP")

                def stop_server():
                    print("🔻 Shutting down server...")
                    self.server.shutdown()

                threading.Thread(target=stop_server).start()

                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"status": "Server shutting down"}).encode())
                return

            #Normal GET request processing
            query_json = json.dumps({k: v[0] for k, v in query_dict.items()})
            
            request_data = query_json
            print("=== Incoming GET request ===")
            print(f"Query string: {query_json}")
     
            try:

                # Call the RPG program with method = 'GET'
                rpg_result = self.call_rpg('GET', request_data)
                print(f"Return Data: {rpg_result}")

                # Return the result to the client
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(rpg_result.encode())

            except Exception as e:
                print("=== Incoming GET request ===")
                print(f"Query string: {query_json}")

                print("=== RPG Response (raw) ===")
                print(rpg_result)

                print("ERROR during RPG call:", e)
                self.send_response(500)
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode())
        else:
            # Serve regular static files (like index.html, etc.)
            super().do_GET()

    # Handle HTTP POST requests to /api by calling the RPG program
    def do_POST(self):
        if self.path.startswith('/api'):
            content_length = int(self.headers.get('Content-Length', 0))
            content_type = self.headers.get('Content-Type', '')
            
            # Read the POST data
            post_data = self.rfile.read(content_length).decode('utf-8')
            
            print("=== Incoming POST request ===")
            print(f"Content-Type: {content_type}")
            print(f"Raw POST data: {post_data}")

            try:
                # If content is JSON, parse it
                if 'application/json' in content_type:
                    # Parse JSON data
                    json_data = json.loads(post_data)
                    # Convert back to string for RPG program
                    request_data = json.dumps(json_data)
                else:
                    request_data = post_data

                print(f"Processed request data: {request_data}")

                # Call the RPG program with method = 'POST'
                rpg_result = self.call_rpg('POST', request_data)
                print(f"Return Data: {rpg_result}")

                # Return the result to the client
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(rpg_result.encode())

            except json.JSONDecodeError as e:
                print("ERROR parsing JSON:", e)
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    "success": False,
                    "message": f"Invalid JSON format: {str(e)}"
                }).encode())

            except Exception as e:
                print("ERROR during RPG call:", e)
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    "success": False,
                    "message": f"Error processing request: {str(e)}"
                }).encode())
# -----------------------------------------
# START THE SERVER
# -----------------------------------------

if __name__ == '__main__':
    # Setup argument parser
    parser = argparse.ArgumentParser(description='Simple RPG HTTP Server')
    parser.add_argument('--port', type=int, default=43001, help='Port to listen on')
    parser.add_argument('--library', type=str, default='RTHOMPSON1', help='Library to add to library list')

    args = parser.parse_args()

    # Save the library name globally
    RPGHTTPRequestHandler.LIBRARY = args.library

    # Start the HTTP server
    port = args.port
    server = ThreadingHTTPServer(('0.0.0.0', port), RPGHTTPRequestHandler)
    print(f"Serving on http://localhost:{port} using library {args.library}")
    print("Press Ctrl+C to stop the server")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n⚠️Shutting down server gracefully...")
        server.shutdown()
        server.server_close()
        print("🔻Server shutdown complete")
