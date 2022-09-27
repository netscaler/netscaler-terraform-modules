#!/usr/bin/env python3.6

import argparse
import logging
import codecs
import json
import urllib
import urllib.request
import time
import socket
import http
import traceback
import ssl
import sys

if sys.version_info[0] != 3:
    raise Exception('Can only run under python3')


logger = logging.getLogger('main')

class NitroAPIOpener(object):

    def __init__(self, nsip, nitro_protocol='http', api_path='nitro/v1/config', nitro_user=None, nitro_pass=None, nitro_auth_token=None, mas_proxy_call=False, instance_ip=None, instance_name=None, instance_id=None):

        self.nitro_protocol = nitro_protocol
        self.nsip = nsip
        self.instance_id = instance_id

        self.r = None
        self.info = None
        self.api_path = api_path

        # Prepare the http headers according to module arguments
        self._headers = {}
        self._headers['Content-Type'] = 'application/json'

        # Check for conflicting authentication methods
        have_token = nitro_auth_token is not None
        have_userpass = None not in (nitro_user, nitro_pass)

        # if have_token and have_userpass:
        #     self.fail_module(
        #         msg='Cannot define both authentication token and username/password')

        if have_token:
            self._headers['Cookie'] = "NITRO_AUTH_TOKEN=%s" % nitro_auth_token

        if have_userpass:
            self._headers['X-NITRO-USER'] = nitro_user
            self._headers['X-NITRO-PASS'] = nitro_pass

        # Do header manipulation when doing a MAS proxy call
        if mas_proxy_call:
            if instance_ip is not None:
                self._headers['_MPS_API_PROXY_MANAGED_INSTANCE_IP'] = instance_ip
            elif instance_name is not None:
                self._headers['_MPS_API_PROXY_MANAGED_INSTANCE_NAME'] = instance_name
            elif instance_id is not None:
                self._headers['_MPS_API_PROXY_MANAGED_INSTANCE_ID'] = instance_id
            else:
                raise Exception(
                    'Target netscaler is undefined for MAS proxied NITRO call')

    def edit_response_data(self, r, info, result):
        '''
            Parses the r and info values from ansible fetch
            and manipulates the result accordingly
        '''

        # Save raw values to corresponding member variables
        self.r = r
        self.info = info

        # Search for body in both http body and http data
        if r is not None:
            result['http_response_body'] = codecs.decode(r.read(), 'utf-8')
        elif 'body' in info:
            result['http_response_body'] = codecs.decode(info['body'], 'utf-8')
            del info['body']
        else:
            result['http_response_body'] = ''

        result['http_response_data'] = info
        try:
            result['http_response_code'] = r.getcode()
        except AttributeError:
            result['http_response_code'] = 0

        # Update the nitro_* parameters

        # Nitro return code in http data
        result['nitro_errorcode'] = None
        result['nitro_message'] = None
        result['nitro_severity'] = None

        if result['http_response_body'] != '':
            try:
                data = from_json(result['http_response_body'])

                # Get rid of the string representation if json parsing succeeds
                del result['http_response_body']
            except ValueError:
                data = {}
            result['data'] = data
            result['nitro_errorcode'] = data.get('errorcode')
            result['nitro_message'] = data.get('message')
            result['nitro_severity'] = data.get('severity')

    def _construct_query_string(self, args=None, attrs=None, filter=None, action=None, count=False):

        query_dict = {}

        args = {} if args is None else args
        attrs = [] if attrs is None else attrs
        filter = {} if filter is None else filter

        # Construct args
        args_val = ','.join(
            ['%s:%s' % (k, urllib.parse.quote(args[k], safe='')) for k in args])

        if args_val != '':
            args_val = 'args=%s' % args_val

        # Construct attrs
        attrs_val = ','.join(attrs)
        if attrs_val != '':
            attrs_val = 'attrs=%s' % attrs_val

        # Construct filters
        filter_val = ','.join(['%s:%s' % (k, filter[k]) for k in filter])
        if filter_val != '':
            filter_val = 'filter=%s' % filter_val

        # Construct action
        action_val = ''
        if action is not None:
            action_val = 'action=%s' % action

        # Construct count
        count_val = ''
        if count:
            count_val = 'count=yes'

        # Construct the query string
        # Filter out empty string parameters
        val_list = [args_val, attrs_val, filter_val, action_val, count_val]
        query_params = '&'.join([v for v in val_list if v != ''])

        if query_params != '':
            query_params = '?%s' % query_params

        return query_params

    def put(self, put_data, resource, id=None):
        logger.debug('put_data {}'.format(put_data))

        if id != None:
            url = '%s://%s/%s/%s/%s' % (
                self.nitro_protocol,
                self.nsip,
                self.api_path,
                resource,
                id,
            )
        else:
            url = '%s://%s/%s/%s' % (
                self.nitro_protocol,
                self.nsip,
                self.api_path,
                resource
            )

        data = to_json(put_data)

        r, info = open_url(
            url=url,
            headers=self._headers,
            data=data,
            method='PUT',
        )

        result = {}
        self.edit_response_data(r, info, result)

        return result

    def get(self, resource, id=None, args=None, attrs=None, filter=None):

        args = {} if args is None else args
        attrs = [] if attrs is None else attrs
        filter = {} if filter is None else filter

        # Construct basic get url
        url = '%s://%s/%s/%s' % (
            self.nitro_protocol,
            self.nsip,
            self.api_path,
            resource,
        )

        # Append resource id
        if id is not None:
            url = '%s/%s' % (url, id)

        query_params = self._construct_query_string(
            args=args, attrs=attrs, filter=filter)

        # Append query params
        url = '%s%s' % (url, query_params)

        r, info = open_url(
            url=url,
            headers=self._headers,
            method='GET',
        )

        result = {}
        self.edit_response_data(r, info, result)

        return result

    def delete(self, resource, id=None, args=None):

        args = {} if args is None else args

        # Deletion by name takes precedence over deletion by attributes

        url = '%s://%s/%s/%s' % (
            self.nitro_protocol,
            self.nsip,
            self.api_path,
            resource
        )

        # Append resource id
        if id is not None:
            url = '%s/%s' % (url, id)

        # Append query params
        query_params = self._construct_query_string(args=args)
        url = '%s%s' % (url, query_params)

        r, info = open_url(
            url=url,
            headers=self._headers,
            method='DELETE',
        )

        result = {}
        self.edit_response_data(r, info, result)

        return result

    def post(self, post_data, resource, action=None):
        logger.debug('post_data {}'.format(post_data))

        # Construct basic get url
        url = '%s://%s/%s/%s' % (
            self.nitro_protocol,
            self.nsip,
            self.api_path,
            resource,
        )

        query_params = self._construct_query_string(action=action)

        # Append query params
        url = '%s%s' % (url, query_params)

        data = to_json(post_data)

        logger.debug('POST REQUEST URL:{}'.format(url))

        r, info = open_url(
            url=url,
            headers=self._headers,
            data=data,
            method='POST',
        )

        result = {}
        self.edit_response_data(r, info, result)

        return result


def waitfor(seconds, reason=None):
    if reason != None:
        logger.info(
            'Waiting for {} seconds. Reason: {}'.format(seconds, reason))
    else:
        logger.info('Waiting for {} seconds'.format(seconds))
    time.sleep(seconds)


def to_json(data):
    return codecs.encode(json.dumps(data))

def from_json(data):
    return json.loads(data)


def open_url(url, headers, data=None, method=None):
    method = 'GET' if method is None else method

    request = urllib.request.Request(
        url=url,
        headers=headers,
        data=data,
        method=method,
    )

    # Give a 3 seconds sleep for the command to get execute on
    waitfor(3, reason='Executing {} method on URL: {} with data: {}'.format(method, url, data))

    info = dict(url=url)
    r = None
    try:
        # We do not verify SSL
        context = ssl.SSLContext()
        context.verify_mode = ssl.CERT_NONE

        # Do the HTTP request
        r = urllib.request.urlopen(request, context=context)
        info.update(dict((k.lower(), v) for k, v in r.info().items()))
    except urllib.error.HTTPError as e:
        try:
            body = e.read()
        except AttributeError:
            body = ''

        # Try to add exception info to the output but don't fail if we can't
        try:
            # Lowercase keys, to conform to py2 behavior, so that py3 and py2 are predictable
            info.update(dict((k.lower(), v) for k, v in e.info().items()))
        except Exception:
            pass

        info.update({'msg': str(e), 'body': body, 'status': e.code})
    except urllib.error.URLError as e:
        code = int(getattr(e, 'code', -1))
        info.update(dict(msg='Request failed: %s' % str(e), status=code))
    except socket.error as e:
        info.update(dict(msg='Connection failure: %s' % str(e), status=-1))
    except http.client.BadStatusLine as e:
        info.update(dict(msg='Connection failure: connection was closed before a valid response was received: %s' % str(
            e.line), status=-1))
    except Exception as e:
        info.update(dict(msg='An unknown error occurred: %s' % str(e), status=-1),
                    exception=traceback.format_exc())

    return r, info

def wait_reachability(instance_id, tries=20, interval=30):
    ec2_client = boto3.client('ec2')
    current_try = 1
    while 1:
        response = ec2_client.describe_instance_status(
            Filters=[],
            InstanceIds=[instance_id],
        )

        r_status = response['InstanceStatuses'][0]['InstanceStatus']['Details'][0]['Status']
        print('Rechability Status for {}: {}'.format(instance_id, r_status))
        if r_status == 'passed':
            break
        else:
            current_try += 1
            if current_try > tries:
                # Fail execution
                raise Exception('Exceeded maximum tries {}'.format(tries))
            else:
                print('Sleeping for {} seconds'.format(interval))
                time.sleep(interval)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--nsip', required=True)
    parser.add_argument('--nitro-user', required=True)
    parser.add_argument('--nitro-pass', required=True)

    parser.add_argument('--reboot', action='store_true')


    parser.add_argument('--license-server-ip')
    parser.add_argument('--license-server-port', default=27000)
    parser.add_argument('--license-mode', choices=['cico', 'vcpu', 'pooled'])
    parser.add_argument('--platform')
    parser.add_argument('--edition')
    parser.add_argument('--bandwidth')
    parser.add_argument('--units', choices=['Mbps', 'Gbps'], default='Mbps')

    parser.add_argument('--check-reachability', action='store_true')
    parser.add_argument('--instance-id')
    parser.add_argument('--interval', default=30)
    parser.add_argument('--tries', default=20)

    args = parser.parse_args()


    # Wait reachability
    if args.check_reachability:
        wait_reachability(args.instance_id, args.tries, args.interval)

    nitro_client = NitroAPIOpener(
        nsip=args.nsip,
        nitro_user=args.nitro_user,
        nitro_pass=args.nitro_pass,
        nitro_protocol='http',
    )

    # Add license server
    post_data = {
        'nslicenseserver': {
            'servername': args.license_server_ip,
            'port': args.license_server_port,
        }
    }
    result = nitro_client.post(resource='nslicenseserver', post_data=post_data)

    if result['nitro_errorcode'] == 0 or result['nitro_errorcode'] is None:
        logger.info('SUCCESS: Added {} as License Server in {}'.format(
            args.license_server_ip, args.nsip))
    elif result['nitro_errorcode'] == 273:  # License Server already exists
        logger.info('License Server {} already exists'.format(args.license_server_ip))
    else:
        raise Exception('FAIL: Could not add License Server\n HTTP response {}'.format(result))

    # Add license
    put_data = {}
    if args.license_mode == 'cico':
        put_data = {
            'nscapacity': {
                    'platform': args.platform
            }
        }
    elif args.license_mode == 'pooled':
        put_data = {
            'nscapacity': {
                'bandwidth': args.bandwidth,
                'edition': args.edition,
                'unit': args.units,
            }
        }
    elif args.license_mode == 'vcpu':
        put_data = {
            'nscapacity': {
                'vcpu': True,
                'edition': args.edition,
            }
        }

    result = nitro_client.put(put_data=put_data, resource='nscapacity')
    if result['nitro_errorcode'] == 0:
        print('SUCCESS: Allocating license')
    else:
        raise Exception('FAIL: Could not allocate license\n HTTP response {}'.format(result))

    # Warm reboot to apply license
    if args.reboot:
        # Save config
        # Reboot
        post_data = {
            'reboot': {
                'warm': True
            }
        }
        nitro_client.post(resource='reboot', post_data=post_data)



if __name__ == '__main__':
    main()
