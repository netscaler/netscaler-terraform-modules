import json
import logging
import yaml
import time
import requests

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


# Global Variables
CLIP = ""
NODES = []
MAX_RETRIES = 10


def waitfor(seconds=2, reason=None):
    if reason is not None:
        logger.info(
            'Waiting for {} seconds. Reason: {}'.format(seconds, reason))
    else:
        logger.info('Waiting for {} seconds'.format(seconds))
    time.sleep(seconds)


class HTTPNitro():
    def __init__(self, nsip, nsuser='nsroot', nspass='nsroot', nitro_protocol='http', ns_api_path='nitro/v1/config'):
        self.nitro_protocol = nitro_protocol
        self.api_path = ns_api_path
        self.nsip = nsip
        self.nsuser = nsuser
        self.nspass = nspass

        self.headers = {}
        self.headers['Content-Type'] = 'application/json'
        self.headers['X-NITRO-USER'] = self.nsuser
        self.headers['X-NITRO-PASS'] = self.nspass

    def construct_url(self, resource,  id=None, action=None):
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

        # Append action
        if action is not None:
            url = '%s?action=%s' % (url, action)

        return url

    def check_connection(self):
        url = self.construct_url(resource='login')

        headers = {}
        headers['Content-Type'] = 'application/json'
        payload = {
            "login": {
                "username": self.nsuser,
                "password": self.nspass
            }
        }
        try:
            r = requests.post(url=url, headers=headers, json=payload)
            response = r.json()
            logger.debug("do_login response: {}".format(
                json.dumps(response, indent=4)))
            if response['severity'] == 'ERROR':
                logging.error('Could not login to {}'.format(self.nsip))
                logging.error('{}: {}'.format(
                    response['errorcode'], response['message']))
                return False
            return True
        except Exception as e:
            logger.error('Node {} is not reachable. Reason:{}'.format(self.nsip, str(e)))
            return False

    def do_get(self, resource, id=None, action=None):
        url = self.construct_url(resource, id, action)
        logger.debug('GET {}'.format(url))

        r = requests.get(
            url=url,
            headers=self.headers,
            verify=False,
        )
        if r.status_code == 200:
            response = r.json()
            logger.debug("do_get response: {}".format(
                json.dumps(response, indent=4)))
            return response
        else:
            logger.error('GET failed: {}'.format(r.text))
            return False

    def do_post(self, resource, data, id=None, action=None):
        url = self.construct_url(resource, id, action)
        logger.debug('POST {}'.format(url))
        logger.debug('POST data: {}'.format(json.dumps(data, indent = 4)))

        r = requests.post(
            url=url,
            headers=self.headers,
            json=data,
        )
        # print(r.text)
        logger.info(r.status_code)
        if r.status_code == 201 or r.status_code == 200:
            return True
        else:
            logger.error('POST failed: {}'.format(r.text))
            return False

    def do_put(self, resource, data, id=None, action=None):
        url = self.construct_url(resource, id, action)
        logger.debug('PUT {}'.format(url))
        logger.debug('PUT data: {}'.format(json.dumps(data, indent = 4)))

        r = requests.put(
            url=url,
            headers=self.headers,
            json=data,
        )
        if r.status_code == 201 or r.status_code == 200:
            return True
        else:
            logger.error('PUT failed: {}'.format(r.text))
            return False

    def do_delete(self, resource, id=None, action=None):
        url = self.construct_url(resource, id, action)
        logger.debug('DELETE {}'.format(url))

        r = requests.delete(
            url=url,
            headers=self.headers,
        )
        if r.status_code == 200:
            return True
        else:
            return False


class CitrixADC(HTTPNitro):
    def __init__(self, nsip, nsuser='nsroot', nspass='nsroot'):
        super().__init__(nsip=nsip, nsuser=nsuser, nspass=nspass)

    def add_cluster_instance(self, instID):
        data = {"clusterinstance": {
            "clid": str(instID),
        }}
        result = self.do_post(resource='clusterinstance',
                                 data=data)
        if result:
            logger.info('Successfully added cluster instance {} to {}'.format(instID, self.nsip))
        else:
            logger.error('Could not add cluster instance {} to {}'.format(instID, self.nsip))
            logger.error('Refer log file for more information')
            raise Exception

    def enable_cluster_instance(self, instID):
        data = {"clusterinstance": {
            "clid": str(instID),
        }}
        result = self.do_post(resource='clusterinstance',
                                 data=data, action="enable")
        if result:
            logger.info('Successfully enabled cluster instance {} to {}'.format(instID, self.nsip))
        else:
            logger.error('Could not enabled cluster instance {} to {}'.format(instID, self.nsip))
            logger.error('Refer log file for more information')
            raise Exception

    def add_cluster_node(self, nodeID, nodeIP, backplane, tunnelmode, state):
        data = {"clusternode": {
            "nodeid": str(nodeID),
            "ipaddress": nodeIP,
            "state": state,
            "backplane": backplane,
            "tunnelmode": tunnelmode
        }}
        result = self.do_post(resource='clusternode',
                                 data=data)
        if result:
            logger.info('Successfully added cluster node with ID:{} and nodeIP:{}'.format(nodeID, nodeIP))
        else:
            logger.error('Could not add cluster node with ID:{} and nodeIP:{}'.format(nodeID, nodeIP))
            logger.error('Refer log file for more information')
            raise Exception

    def set_cluster_node(self, nodeID, state):
        data = {"clusternode": {
            "nodeid": str(nodeID),
            "state": state,
        }}
        result = self.do_put(resource='clusternode',
                                data=data)
        if result:
            logger.info('Successfully set cluster node {} to state {}'.format(nodeID, state))
        else:
            logger.error('Could not add cluster node {} to state {}'.format(nodeID, state))
            logger.error('Refer log file for more information')
            raise Exception

    def remove_cluster_node(self, nodeID):
        result = self.do_delete(resource='clusternode',
                                   id=str(nodeID))
        if result:
            logger.info('Successfully removed cluster node {}'.format(nodeID))
        else:
            logger.error('Could not remove cluster node {}'.format(nodeID))
            logger.error('Refer log file for more information')
            raise Exception

    def join_cluster(self, clip, password):
        data = {"cluster": {
            "clip": clip,
            "password": password
        }}
        result = self.do_post(resource='cluster',
                                 data=data, action="join")
        if result:
            logger.info('Successfully joined cluster node {}'.format(self.nsip))
        else:
            logger.error('Could not join cluster node {}'.format(self.nsip))
            logger.error('Refer log file for more information')
            raise Exception

    def add_nsip(self, ip, netmask, ip_type):
        data = {"nsip": {
            "ipaddress": ip,
            "netmask": netmask,
            "type": ip_type
        }}
        result = self.do_post(resource='nsip',
                                 data=data)
        if result:
            logger.info('Successfully added NSIP {} with type {}'.format(ip, ip_type))
        else:
            logger.error('Could not add NSIP {} with type {}'.format(ip, ip_type))
            logger.error('Refer log file for more information')
            raise Exception

    def save_config(self):
        data = {
            'nsconfig': {}
        }
        result = self.do_post(resource='nsconfig',
                                 data=data, action="save")
        if result:
            logger.info('Successfully saved nsconfig of {}'.format(self.nsip))
        else:
            logger.error('Could not save nsconfig of {}'.format(self.nsip))
            logger.error('Refer log file for more information')
            raise Exception

    def reboot(self, warm=True):
        data = {
            "reboot": {
                "warm": warm
            }
        }
        result = self.do_post(resource='reboot',
                                 data=data)
        if result:
            logger.info('Successfully reboot {}'.format(self.nsip))
            waitfor(70, reason='Waiting for {} to come up after reboot'.format(self.nsip))
        else:
            logger.error('Could not reboot {}'.format(self.nsip))
            logger.error('Refer log file for more information')
            raise Exception

    def change_password(self, new_pass='nsroot'):
        # check for new_pass already updated
        self.nspass = new_pass
        logger.debug('Before changing the password of {}, checking if the password is already updated'.format(self.nsip))
        if self.check_connection():
            logger.info('Password already changed to {}'.format(new_pass))
            self.headers['X-NITRO-PASS'] = self.nspass
            return True
        else:
            data = {"systemuser": {
                "username": self.nsuser,
                "password": new_pass,
            }}
            result = self.do_put(resource='systemuser',
                                    data=data)

            if result:
                self.nspass = new_pass
                self.headers['X-NITRO-PASS'] = self.nspass
                logger.info('Successfully changed password of {} to {}'.format(self.nsip, new_pass))
                return True
            else:
                logger.error('Could not change password of {} to {}'.format(self.nsip, new_pass))
                logger.error('Refer log file for more information')
                raise Exception


def get_current_cluster_nodes():
    cc = CitrixADC(CLIP)
    if not cc.check_connection():
        return False

    result = cc.do_get(resource='clusternode')
    return result['clusternode']

def check_clusternode_status(nodeip):
    # Before calling this function, CLIP should already been established
    # login to cluster and check the status
    # TODO: retry needed
    cc = CitrixADC(CLIP)
    if not cc.check_connection():
        return False

    num_retries = 0
    while num_retries < MAX_RETRIES:
        num_retries += 1
        result = cc.do_get(resource='clusternode')
        if result:
            clusternodes_list = result['clusternode']
            # check each cluster node's Health, Operational State. Wait for MAX_RETRIES and exit if not ACTIVE
            # Operational Sync State: SUCCESS, ENABLED, UNKNOWN
            # Health -->  UNKNOWN, INIT, DOWN, UP
            # Master State -->  INACTIVE, ACTIVE, UNKNOWN
            # Effective State --> UP, NOT UP, UNKNOWN, INIT
            # Success state: masterstate == ACTIVE, Health == UP
            for cnode in clusternodes_list:
                cnode_ip = cnode['ipaddress']
                if cnode_ip != nodeip:
                    continue
                cnode_id = cnode['nodeid']
                # cnode_op_sync_state = cnode['operationalsyncstate']
                # cnode_health = cnode['health']
                # cnode_state = cnode['state']
                cnode_masterstate = cnode['masterstate']

                if cnode_masterstate == 'ACTIVE': # TODO: Is `Health` need to check up?
                    return True
                else:
                    waitfor(20, reason='Try: {}/{}. Waiting for node id:{} ip:{} to become ACTIVE'.format(num_retries, MAX_RETRIES, cnode_id, cnode_ip))

    if num_retries == MAX_RETRIES:
        logging.error('The node id:{} ip:{} could not become ACTIVE. Plese login to the node for more details'.format(cnode_id, cnode_ip))
        return False


def add_first_node_to_cluster(n):
    nsip = n['NSIP']
    nodeID = n['ID']
    backplane = '{}/1/1'.format(nodeID)
    tunnelmode = 'GRE'
    state = 'ACTIVE'
    clusterInstanceID = 1  # TODO: need to take cluster instance ID as input

    node = CitrixADC(nsip)
    if not node.check_connection():
        logging.error('Node {} not reachable'.format(nsip))
        exit()
    node.add_cluster_instance(clusterInstanceID)
    node.add_cluster_node(nodeID, nsip, backplane, tunnelmode, state)
    node.add_nsip(CLIP, '255.255.255.255', 'CLIP')
    node.enable_cluster_instance(clusterInstanceID)
    node.save_config()
    node.reboot()
    if not check_clusternode_status(nodeip=nsip):
        logger.error('Node id:{} ip:{} failed to add to the cluster'.format(nodeID, nsip))
        return False
    logger.info('Successfully added node id:{} ip:{} to cluster'.format(nodeID, nsip))
    return True


def add_rest_nodes_to_cluster(rest_nodes):
    # for every node
        # login to CLIP, add node
        # login to node, join CLIP
    for n in rest_nodes:
        nsip = n['NSIP']
        nodeID = n['ID']
        backplane = '{}/1/1'.format(nodeID)
        tunnelmode = 'GRE'
        state = 'ACTIVE'

        # Connect to Cluster Coordinator
        cc = CitrixADC(CLIP)
        if not cc.check_connection():
            logging.error('Node {} not reachable'.format(nsip))
            exit()

        cc.add_cluster_node(nodeID, nsip, backplane, tunnelmode, state)
        cc.save_config()

        # Connect to node
        node = CitrixADC(nsip)
        if not node.check_connection():
            logging.error('Node {} not reachable'.format(nsip))
            exit()

        node.join_cluster(CLIP, 'nsroot') # TODO: need to take password as input
        node.save_config()
        node.reboot()
        if not check_clusternode_status(nodeip=nsip):
            logger.error('Node id:{} ip:{} failed to join the cluster'.format(nodeID, nsip))
            # If one node addition fails, do not process other nodes in queue
            break
        else:
            logger.info('Successfully added node id:{} ip:{} to cluster'.format(nodeID, nsip))


if __name__ == "__main__":
    input_data = yaml.load(open("cluster-input.yaml"))
    logger.debug(json.dumps(input_data, indent=4))

    # Populate the CLIP and NODES information to global variables
    try:
        CLIP = input_data['CLUSTER_IP']
        NODES = input_data['NODES']
    except KeyError as e:
        logger.error('Exception occured while parsing the input: {}'.format(str(e)))
        exit()

    # Check if the CLIP is already reachable
    current_node_dict = get_current_cluster_nodes()
    if current_node_dict:
        # CLIP is reachable, modify(add or delete nodes) the existing cluster
        current_node_ips = []
        current_node_ids = []
        new_node_ids = []
        new_node_ips = []
        for n in current_node_dict:
            current_node_ips.append(n['ipaddress'])
            current_node_ids.append(n['nodeid'])

        for n in NODES:
            new_node_ips.append(n['NSIP'])
            new_node_ids.append(str(n['ID']))

        if len(current_node_dict) < len(NODES):
            # TODO: Change the logic to (id, ip) tuple to ensure nodeid and nodeip wont mismatch
            # TODO: try to do add and delete at the same time. Try not to have if-else separately
            # add new nodes
            node_ips_to_add = list(set(new_node_ips) - set(current_node_ips))
            node_ids_to_add = list(set(new_node_ids) - set(current_node_ids))
            logger.info('New node IPs to add: {}'.format(node_ips_to_add))
            # form new nodes dictionary
            node_dict_to_add = []
            for i in range(len(node_ips_to_add)):
                new_node = {}
                new_node['NSIP'] = node_ips_to_add[i]
                new_node['ID'] = node_ids_to_add[i]
                node_dict_to_add.append(new_node)
            logger.info('Nodes to be added: {}'.format(node_dict_to_add))
            add_rest_nodes_to_cluster(node_dict_to_add)
        else:
            # delete current nodes
            node_ips_to_delete = list(set(current_node_ips) - set(new_node_ips))
            node_ids_to_delete = list(set(current_node_ids) - set(new_node_ids))
            logger.info('Node IPs to delete: {}'.format(node_ips_to_delete))
            cc = CitrixADC(CLIP)
            for nodeID in node_ids_to_delete:
                cc.remove_cluster_node(nodeID)
                cc.save_config()

    else:
        # TODO: there can be another reason where CLIP is not reacbale. Handle them
        # CLIP not reacbale. Create new cluster
        # add first node to the cluster
        add_first_node_to_cluster(NODES[0])
        if len(NODES) > 1:
            # join other nodes
            if add_rest_nodes_to_cluster(NODES[1:]):
                logger.info('Successfully added nodes {} to cluster'.format(NODES))

# check all node's status at last
    nodes_not_added = []
    for node in NODES:
        nsip = n['NSIP']
        if not check_clusternode_status(nsip):
            nodes_not_added.append(nsip)
    if not nodes_not_added:
        logging.error('Nodes not added to cluster: {}'.format(nodes_not_added))
    else:
        logging.info('All nodes added to cluster')
