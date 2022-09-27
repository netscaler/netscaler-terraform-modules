import json
import logging
import time
import requests

LOGFILE = __file__ + '.log'
formatter = logging.Formatter('%(asctime)s: %(levelname)s - %(message)s')

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
NSPASS = 'nsroot'
NODES = []
MAX_RETRIES = 40


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
            logger.debug('post_data: {}'.format(json.dumps(payload, indent=4)))
            logger.debug('HEADERS: {}'.format(json.dumps(self.headers, indent=4)))
            r = requests.post(url=url, headers=headers, json=payload)
            response = r.json()
            logger.debug("do_login response: {}".format(
                json.dumps(response, indent=4)))
            if response['severity'] == 'ERROR':
                logger.error('Could not login to {} with user:{} and passwd:{}'.format(self.nsip, self.nsuser, self.nspass))
                logger.error('{}: {}'.format(
                    response['errorcode'], response['message']))
                return False
            return True
        except Exception as e:
            logger.error(
                'Node {} is not reachable. Reason:{}'.format(self.nsip, str(e)))
            return False

    def do_get(self, resource, id=None, action=None):
        url = self.construct_url(resource, id, action)
        logger.debug('GET {}'.format(url))
        logger.debug('HEADERS: {}'.format(json.dumps(self.headers, indent=4)))

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
        logger.debug('POST data: {}'.format(json.dumps(data, indent=4)))
        logger.debug('HEADERS: {}'.format(json.dumps(self.headers, indent=4)))

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
        logger.debug('PUT data: {}'.format(json.dumps(data, indent=4)))
        logger.debug('HEADERS: {}'.format(json.dumps(self.headers, indent=4)))

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
        logger.debug('HEADERS: {}'.format(json.dumps(self.headers, indent=4)))

        r = requests.delete(
            url=url,
            headers=self.headers,
        )
        # response = r.json()
        # logger.debug("do_delete response: {}".format(
        #     json.dumps(response, indent=4)))
        if r.status_code == 200:
            return True
        else:
            return False


class CitrixADC(HTTPNitro):
    def __init__(self, nsip, nsuser='nsroot', nspass='nsroot'):
        super().__init__(nsip=nsip, nsuser=nsuser, nspass=nspass)

    def get_clip(self):
        result = self.do_get(resource='nsip')
        if result:
            for ip_dict in result['nsip']:
                if ip_dict['type'] == 'CLIP':
                    return ip_dict['ipaddress']
            return False # No CLIP found

    def add_cluster_instance(self, instID):
        data = {"clusterinstance": {
            "clid": str(instID),
        }}
        result = self.do_post(resource='clusterinstance',
                              data=data)
        if result:
            logger.info('Successfully added cluster instance {} to {}'.format(
                instID, self.nsip))
        else:
            logger.error(
                'Could not add cluster instance {} to {}'.format(instID, self.nsip))
            logger.error('Refer log file for more information')
            raise Exception

    def enable_cluster_instance(self, instID):
        data = {"clusterinstance": {
            "clid": str(instID),
        }}
        result = self.do_post(resource='clusterinstance',
                              data=data, action="enable")
        if result:
            logger.info('Successfully enabled cluster instance {} to {}'.format(
                instID, self.nsip))
        else:
            logger.error(
                'Could not enabled cluster instance {} to {}'.format(instID, self.nsip))
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
            logger.info('Successfully added cluster node with ID:{} and nodeIP:{}'.format(
                nodeID, nodeIP))
        else:
            logger.error(
                'Could not add cluster node with ID:{} and nodeIP:{}'.format(nodeID, nodeIP))
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
            logger.info(
                'Successfully set cluster node {} to state {}'.format(nodeID, state))
        else:
            logger.error(
                'Could not add cluster node {} to state {}'.format(nodeID, state))
            logger.error('Refer log file for more information')
            raise Exception

    def remove_cluster_node(self, nodeID):
        result = None
        try:
            result = self.do_delete(resource='clusternode',
                                id=str(nodeID))
        except Exception as e:
            logger.error('Unable to fetch response from the CLIP. Reason:{}'.format(str(e)))
            return
        
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
            logger.info(
                'Successfully joined cluster node {}'.format(self.nsip))
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
            logger.info(
                'Successfully added NSIP {} with type {}'.format(ip, ip_type))
        else:
            logger.error(
                'Could not add NSIP {} with type {}'.format(ip, ip_type))
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
            # Do not raise exception, since more than one node is saving at the same time
            # raise Exception

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
        else:
            logger.error('Could not reboot {}'.format(self.nsip))
            logger.error('Refer log file for more information')
            raise Exception

    def change_password(self, new_pass='nsroot'):
        # check for new_pass already updated
        self.nspass = new_pass
        logger.info(
            'Before changing the password of {} to {}, checking if the password is already updated'.format(self.nsip, self.nspass))
        if self.check_connection():
            logger.info('Password already changed to {}'.format(self.nspass))
            self.headers['X-NITRO-PASS'] = self.nspass
            return True
        else:
            logger.info('Password has not been changed earlier, need to change it')
            data = {"systemuser": {
                "username": self.nsuser,
                "password": new_pass,
            }}
            result = self.do_put(resource='systemuser',
                                 data=data)

            if result:
                self.nspass = new_pass
                self.headers['X-NITRO-PASS'] = self.nspass
                logger.info('Successfully changed password of {} to {}'.format(
                    self.nsip, new_pass))
                return True
            else:
                logger.error('Could not change password of {} to {}'.format(
                    self.nsip, new_pass))
                logger.error('Refer log file for more information')
                raise Exception


def get_current_cluster_nodes():
    cc = CitrixADC(nsip=CLIP, nspass=NSPASS)
    if not cc.check_connection():
        return False

    result = cc.do_get(resource='clusternode')
    return result['clusternode']


def check_clusternode_status(nodeip):
    # Before calling this function, CLIP should already been established
    # login to cluster and check the status
    # Retry twice to reach
    for i in [1, 2]:
        cc = CitrixADC(nsip=CLIP, nspass=NSPASS)
        if not cc.check_connection():
            if i == 1:
                logging.debug('Trying again to connect to CLIP:{}'.format(CLIP))
                continue
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

                if cnode_masterstate == 'ACTIVE':  # Is `Health` need to check up?
                    return True
                else:
                    waitfor(10, reason='Try: {}/{}. Waiting for node id:{} ip:{} to become ACTIVE'.format(
                        num_retries, MAX_RETRIES, cnode_id, cnode_ip))

    if num_retries == MAX_RETRIES:
        logger.error('The node ip:{} could not become ACTIVE. Plese login to the node for more details'.format(nodeip))
        return False


def add_first_node_to_cluster(nodeip, backplane='1/1', tunnelmode='GRE'):
    nsip = nodeip
    nodeID = 0 # Auto-assign
    backplane = '{}/{}'.format(nodeID, backplane)
    # tunnelmode = 'GRE'
    state = 'ACTIVE'
    clusterInstanceID = 1  # TODO: need to take cluster instance ID as input

    node = CitrixADC(nsip=nsip, nspass=NSPASS)
    if not node.check_connection():
        logger.error('Node {} not reachable'.format(nsip))
        exit()
    node.add_cluster_instance(clusterInstanceID)
    node.add_cluster_node(nodeID, nsip, backplane, tunnelmode, state)
    node.add_nsip(CLIP, '255.255.255.255', 'CLIP')
    node.enable_cluster_instance(clusterInstanceID)
    node.save_config()
    node.reboot()
    waitfor(70, reason='Waiting for first node to reboot')
    if not check_clusternode_status(nodeip=nsip):
        logger.error(
            'Node id:{} ip:{} failed to add to the cluster'.format(nodeID, nsip))
        return False
    logger.info(
        'Successfully added node id:{} ip:{} to cluster'.format(nodeID, nsip))
    return True


def add_rest_nodes_to_cluster(rest_nodeips, rest_nodeids, cluster_backplane='1/1', tunnelmode='GRE'):
    # for every node
        # login to CLIP, add node
        # login to node, join CLIP
    for i in range(len(rest_nodeips)):
        nsip = rest_nodeips[i]
        nodeID = rest_nodeids[i]
        backplane = '{}/{}'.format(nodeID, cluster_backplane)
        # tunnelmode = 'GRE'
        state = 'ACTIVE'

        # Connect to Cluster Coordinator
        cc = CitrixADC(nsip=CLIP, nspass=NSPASS)
        if not cc.check_connection():
            logger.error('Node {} not reachable'.format(nsip))
            exit()

        cc.add_cluster_node(nodeID, nsip, backplane, tunnelmode, state)
        try:
            cc.save_config()
        except Exception as e:
            logger.error('Failed to save config for CLIP {} while adding node:{}. Reason:{}'.format(CLIP, nsip, str(e)))

        # Connect to node
        node = CitrixADC(nsip, nspass=NSPASS)
        if not node.check_connection():
            logger.error('Node {} not reachable'.format(nsip))
            exit()

        node.join_cluster(CLIP, NSPASS)
        node.save_config()
        node.reboot()
        if not check_clusternode_status(nodeip=nsip):
            logger.error(
                'Node id:{} ip:{} failed to join the cluster'.format(nodeID, nsip))
            # If one node addition fails, do not process other nodes in queue
            break
        else:
            logger.info(
                'Successfully added node id:{} ip:{} to cluster'.format(nodeID, nsip))

def change_initial_password(nodeips, instids):
    logger.debug('change_initial_password: {} :: {}'.format(nodeips, instids))
    for i in range(len(nodeips)):
        ip = nodeips[i]
        instID = instids[i]
        node = CitrixADC(nsip=ip, nspass=instID)
        node.change_password(new_pass=NSPASS)
        node.save_config()


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--delete', action='store_true')
    parser.add_argument('--clip')
    parser.add_argument('--node-ips', nargs='+')
    parser.add_argument('--all-ips', nargs='+')
    parser.add_argument('--inst-ids', nargs='+')
    parser.add_argument('--backplane', default='1/1')
    parser.add_argument('--tunnelmode', default='GRE')
    parser.add_argument('--nspass', default='nsroot')
    parser.add_argument('--node-ids', nargs='+')
    parser.add_argument('--save-config', action='store_true')

    args = parser.parse_args()

    operation = "delete" if args.delete else "create"
    CLIP = args.clip
    node_ips = args.node_ips
    all_ips = args.all_ips
    node_ids = args.node_ids
    inst_ids = args.inst_ids
    backplane = args.backplane
    tunnelmode = args.tunnelmode
    NSPASS = args.nspass
    do_save_config = args.save_config

    for arg, value in sorted(vars(args).items()):
        logger.info("Argument %s: %r", arg, value)

    if operation == "create" and do_save_config == False:
        # change the password
        change_initial_password(node_ips, inst_ids)

    # find the CLIP, if not given
    # This scenario comes after adding atleast one node to cluster
    if CLIP is None:
        logging.info("CLIP is not passed as agrument. Need to find CLIP")
        for nsip in all_ips:
            logger.debug('all_ips: {}'.format(all_ips))
            nodeObj = CitrixADC(nsip=nsip, nspass=NSPASS)
            if not nodeObj.check_connection():
                continue
            cluster_ip = nodeObj.get_clip()
            if cluster_ip:
                CLIP = cluster_ip
                logger.info("CLIP is {}".format(CLIP))
                break
        if not CLIP:
            logger.error('Count not find CLIP. Exiting...')
            exit()


    if do_save_config:
        # save CLIP config
        # this will be invoved at the end of Terraform

        # check all node's status at last
        nodes_not_added = []
        for nsip in all_ips:
            if not check_clusternode_status(nsip):
                nodes_not_added.append(nsip)
        if nodes_not_added:
            logger.error('Nodes not added to cluster: {}'.format(nodes_not_added))
        else:
            logger.info('All nodes added to cluster and are in ACTIVE state')

        cc = CitrixADC(nsip=CLIP, nspass=NSPASS)
        cc.save_config()
        exit()

    if operation == "create" and len(node_ips) != len(inst_ids):
        logger.error("Mismatch in nodeIPs and instanceIDs: nodeIPs:{} instanceIDs:{}".format(node_ips, inst_ids))
        exit()

    # Check if the CLIP is already reachable
    current_node_dict = get_current_cluster_nodes()
    if current_node_dict:
        # CLIP is reachable, modify(add or delete nodes) the existing cluster
        if operation == "delete": # delete node
            if len(current_node_dict) == 1:
                logger.info('Deleting last node from the cluster')
                exit()
            nodeid_to_delete = None
            nodeip_to_delete = node_ips[0]
            for node in current_node_dict:
                if node['ipaddress'] == nodeip_to_delete:
                    nodeid_to_delete = node['nodeid']
            logger.info('Nodes to be deleted: {}'.format(nodeid_to_delete))
            if nodeid_to_delete is None:
                logger.error('Node {} not found in the current cluster.'.format(nodeip_to_delete))
                exit()
            cc = CitrixADC(nsip=CLIP, nspass=NSPASS)
            cc.remove_cluster_node(nodeid_to_delete)
            cc.save_config()
            logger.info('Successfully deleted node {}'.format(nodeip_to_delete))
            exit()
        else: # add more nodes
            # assuming serial addition, new nodes will be added at the end always
            # so if there are 3 nodes, the new nodes will be from 4th index of the node_ips argument
            current_num_nodes = len(current_node_dict)

            new_node_ips_to_add = node_ips[current_num_nodes:] # list(set(node_ips) - set(current_node_ips))
            new_node_ids_to_add = node_ids[current_num_nodes:]
            logger.info('Nodes to be added: {}'.format(new_node_ips_to_add))
            add_rest_nodes_to_cluster(new_node_ips_to_add, new_node_ids_to_add, backplane, tunnelmode)

    else:
        # TODO: there can be another reason where CLIP is not reacbale. Handle them
        # CLIP not reacbale. Create new cluster
        # add first node to the cluster
        add_first_node_to_cluster(node_ips[0], backplane, tunnelmode)
        
        if len(node_ips) > 1:
            # join other nodes
            if add_rest_nodes_to_cluster(node_ips[1:], node_ids[1:], backplane, tunnelmode):
                logger.info(
                    'Successfully added nodes {} to cluster'.format(node_ips))
