import requests
import json
import logging

#from ansible.module_utils.six.moves.urllib.parse import parse_qs, urlencode, quote
LOGFILE = __file__ + '.log'
formatter = logging.Formatter('%(levelname)s - %(message)s')

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
ch.setFormatter(formatter)
logger.addHandler(ch)

fh = logging.FileHandler(LOGFILE)
fh.setLevel(logging.DEBUG)
fh.setFormatter(formatter)
logger.addHandler(fh)


# logger.debug(json.dumps(response, indent=4))

def waitfor(seconds, reason=None):
    if reason != None:
        logger.info(
            'Waiting for {} seconds. Reason: {}'.format(seconds, reason))
    else:
        logger.info('Waiting for {} seconds'.format(seconds))
    time.sleep(seconds)


class CitrixADCNitro(object):
    login_ip = ""
    username = "nsroot"
    password = ""
    private_nsip = ""
    private_vip = ""
    private_snip = ""
    # sessid = None
    nitro_protocol = 'http'
    api_path = 'nitro/v1/config'

    def __init__(self, login_ip, login_user, login_pass, **kwargs):
        self.login_ip = login_ip
        self.username = login_user
        self.password = login_pass

        for key, value in kwargs.items():
            if key == "private_nsip":
                self.private_nsip = value
            elif key == "private_vip":
                self.private_vip = value
            elif key == "private_nsip":
                self.private_snip = value
            elif key == "nitro_protocol":
                self.nitro_protocol = value
            elif key == "api_path":
                self.api_path = value
            else:
                logger.error("unexpected argument {}".format(key))

        self.headers = {}
        self.headers['Content-Type'] = 'application/json'
        self.headers['X-NITRO-USER'] = self.username
        self.headers['X-NITRO-PASS'] = self.password

        if not self.check_connection():
            exit()

    def check_connection(self):
        # Construct basic get url
        url = '%s://%s/%s/%s' % (
            self.nitro_protocol,
            self.login_ip,
            self.api_path,
            "login",
        )
        headers = {}
        headers['Content-Type'] = 'application/json'
        # headers['X-NITRO-USER'] = 'nsroot'
        # headers['X-NITRO-PASS'] = 'nsroot'
        payload = {
            "login": {
                "username": self.username,
                "password": self.password
            }
        }
        r = requests.post(url=url, headers=headers, json=payload)

        #r = requests.post(url=url,headers=self.headers,data='object=%s' % json.dumps(payload))
        # print(r.text)
        response = r.json()
        logger.debug("do_login response: {}".format(
            json.dumps(response, indent=4)))
        if response['severity'] == 'ERROR':
            logging.error('Could not login to {}'.format(self.login_ip))
            logging.error('{}: {}'.format(
                response['errorcode'], response['message']))
            return False
        return True
        #sessionid = login['login'][0]['sessionid']
        # self.sessid = response['sessionid']

    def do_get(self, resource, id=None):
        # url = self.static_url + resource

        # Construct basic get url
        url = '%s://%s/%s/%s' % (
            self.nitro_protocol,
            self.login_ip,
            self.api_path,
            resource,
        )

        # Append resource id
        if id is not None:
            url = '%s/%s' % (url, id)

        r = requests.get(
            url=url,
            headers=self.headers,
            verify=False,
        )
        response = r.json()
        logger.debug("do_get response: {}".format(
            json.dumps(response, indent=4)))
        return response

    def do_post(self, resource, data, action=None, id=None):
        # Construct basic get url
        url = '%s://%s/%s/%s' % (
            self.nitro_protocol,
            self.login_ip,
            self.api_path,
            resource,
        )

        # Append resource id
        if id is not None:
            url = '%s/%s' % (url, id)

        # Append action
        if action is not None:
            url = '%s?action=%s' % (url, action)

        r = requests.post(
            url=url,
            headers=self.headers,
            json=data,
        )
        # print(r.text)
        # print(r.status_code)
        response = r.json()
        logger.debug("do_post response: {}".format(
            json.dumps(response, indent=4)))
        return response

    def do_put(self, resource, data, id=None):
        # Construct basic get url
        url = '%s://%s/%s/%s' % (
            self.nitro_protocol,
            self.login_ip,
            self.api_path,
            resource,
        )

        # Append resource id
        if id is not None:
            url = '%s/%s' % (url, id)

        r = requests.put(
            url=url,
            headers=self.headers,
            json=data,
        )
        response = r.json()
        logger.debug("do_put response: {}".format(
            json.dumps(response, indent=4)))
        return response

    def do_delete(self, url):
       # Construct basic get url
        url = '%s://%s/%s/%s' % (
            self.nitro_protocol,
            self.login_ip,
            self.api_path,
            resource,
        )

        # Append resource id
        if id is not None:
            url = '%s/%s' % (url, id)

        r = requests.delete(
            url=url,
            headers=self.headers,
        )
        response = r.json()
        logger.debug("do_delete response: {}".format(
            json.dumps(response, indent=4)))
        return response


def add_cluster_instance(adc, instID):
    data = {"clusterinstance": {
        "clid": instID,
    }}
    result = adc.post(resource='nslicenseserver',
                      data=data)


def enable_cluster_instance(adc, instID):
    data = {"clusterinstance": {
        "clid": instID,
    }}
    result = adc.post(resource='nslicenseserver',
                      data=data, action="enable")


def add_cluster_node(adc, nodeID, nodeIP, backplane, tunnelmode, state):
    data = {"clusternode": {
        "nodeid": nodeID,
        "ipaddress": nodeIP,
        "state": state,
        "backplane": backplane,
        "tunnelmode": tunnelmode
    }}
    result = adc.post(resource='clusternode',
                      data=data, action="enable")


def set_cluster_node(adc, nodeID, state):
    data = {"clusternode": {
        "nodeid": nodeID,
        "state": state,
    }}
    result = adc.put(resource='clusternode',
                     data=data)


def remove_cluster_node(nodeID):
    result = adc.delete(resource='clusternode',
                        id=nodeID)


def join_cluster(adc, clip, password):
    data = {"cluster": {
        "clip": clip,
        "password": password
    }}
    result = adc.post(resource='cluster',
                      data=data, action="join")


def add_nsip(adc, ip, netmask, ip_type):
    data = {"nsip": {
        "ipaddress": ip,
        "netmask": netmask,
        "type": ip_type
    }}
    result = adc.post(resource='nsip',
                      data=data)


def save_config(adc):
    data = {
        'nsconfig': {}
    }
    result = adc.post(resource='nsconfig',
                      data=data, action="save")


def reboot(adc, warm=True):
    data = {
        "reboot": {
            "warm": warm
        }
    }
    result = adc.post(resource='reboot',
                      data=data)


def check_cluster_status(adc):
    result = adc.do_get(resource='clusterinstance')
    # check validation on "operationalpropstate"
    return True


adc = CitrixADCNitro(login_ip='13.232.101.111',
                     login_user='nsroot', login_pass='nsroot')
check_cluster_status(adc)
