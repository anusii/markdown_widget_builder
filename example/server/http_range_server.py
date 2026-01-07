### Static web server with HTTP Range request support
###
### Copyright (C) 2026, Software Innovation Institute, ANU.
###
### Licensed under the MIT License (the "License").
###
### License: https://choosealicense.com/licenses/mit/.
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
###
### Authors: Tony Chen

### Usage:
###   cd example
###   flutter build web --release
###   cd build/web
###   python ../../server/http_range_server.py 8080

import os
import sys
import mimetypes
from http.server import HTTPServer, SimpleHTTPRequestHandler


class RangeRequestHandler(SimpleHTTPRequestHandler):
    """HTTP request handler with Range request support for media streaming."""

    def send_head(self):
        """Send response headers with Range request support."""
        path = self.translate_path(self.path)

        if os.path.isdir(path):
            # Try to serve index.html for directory requests
            index_path = os.path.join(path, 'index.html')
            if os.path.exists(index_path):
                path = index_path
            else:
                # Fall back to directory listing
                return super().send_head()

        if not os.path.exists(path):
            self.send_error(404, "File not found")
            return None

        # Get file size and content type
        file_size = os.path.getsize(path)
        content_type, _ = mimetypes.guess_type(path)
        if content_type is None:
            content_type = 'application/octet-stream'

        # Check for Range header
        range_header = self.headers.get('Range')

        if range_header:
            # Parse Range header (e.g., "bytes=0-1023")
            try:
                range_spec = range_header.replace('bytes=', '')
                start_str, end_str = range_spec.split('-')
                start = int(start_str) if start_str else 0
                end = int(end_str) if end_str else file_size - 1

                # Clamp values
                start = max(0, start)
                end = min(end, file_size - 1)

                if start > end or start >= file_size:
                    self.send_error(416, "Requested Range Not Satisfiable")
                    self.send_header('Content-Range', f'bytes */{file_size}')
                    self.end_headers()
                    return None

                content_length = end - start + 1

                # Send 206 Partial Content
                self.send_response(206)
                self.send_header('Content-Type', content_type)
                self.send_header('Content-Length', str(content_length))
                self.send_header('Content-Range',
                                 f'bytes {start}-{end}/{file_size}')
                self.send_header('Accept-Ranges', 'bytes')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()

                # Return file object positioned at start
                f = open(path, 'rb')
                f.seek(start)
                return _RangeFile(f, content_length)

            except (ValueError, AttributeError):
                # Invalid Range header, fall through to normal response
                pass

        # No Range header or invalid, send full file
        self.send_response(200)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(file_size))
        self.send_header('Accept-Ranges', 'bytes')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()

        return open(path, 'rb')

    def do_OPTIONS(self):
        """Handle CORS preflight requests."""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Range')
        self.end_headers()


class _RangeFile:
    """Wrapper for file object to read only a specific range."""

    def __init__(self, file_obj, length):
        self.file = file_obj
        self.remaining = length

    def read(self, size=-1):
        if self.remaining <= 0:
            return b''
        if size < 0 or size > self.remaining:
            size = self.remaining
        data = self.file.read(size)
        self.remaining -= len(data)
        return data

    def close(self):
        self.file.close()


def run_server(port=8000):
    """Start the HTTP server with Range request support."""
    server_address = ('', port)
    httpd = HTTPServer(server_address, RangeRequestHandler)
    print(f"Serving HTTP on http://localhost:{port}")
    print("Press Ctrl+C to stop the server")
    print("")
    print("This server supports HTTP Range requests for video seeking.")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
        httpd.server_close()


if __name__ == '__main__':
    port = 8000
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"Invalid port: {sys.argv[1]}")
            sys.exit(1)

    run_server(port)
