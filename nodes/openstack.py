import logging
import node
from starts_vms import create_vms_mt
from novaclient.client import Client


logger = logging.getLogger("io-perf-tool")


def get_floating_ip(vm):
    addrs = vm.addresses
    for net_name, ifaces in addrs.items():
        for iface in ifaces:
            if iface.get('OS-EXT-IPS:type') == "floating":
                return iface['addr']


def discover_vms(client, search_opts):
    auth = search_opts.pop('auth', {})
    user = auth.get('user')
    password = auth.get('password')
    key = auth.get('key_file')
    servers = client.servers.list(search_opts=search_opts)
    logger.debug("Found %s openstack vms" % len(servers))
    return [node.Node(get_floating_ip(server), ["test_vm"], username=user,
                      password=password, key_path=key)
            for server in servers if get_floating_ip(server)]


def discover_services(client, opts):
    auth = opts.pop('auth', {})
    user = auth.get('user')
    password = auth.get('password')
    key = auth.get('key_file')
    services = []
    if opts['service'] == "all":
        services = client.services.list()
    else:
        if isinstance(opts['service'], basestring):
            opts['service'] = [opts['service']]

        for s in opts['service']:
            services.extend(client.services.list(binary=s))

    host_services_mapping = {}
    for service in services:
        if host_services_mapping.get(service.host):
            host_services_mapping[service.host].append(service.binary)
        else:
            host_services_mapping[service.host] = [service.binary]
    logger.debug("Found %s openstack service nodes" %
                 len(host_services_mapping))
    return [node.Node(host, services, username=user,
                      password=password, key_path=key) for host, services in
            host_services_mapping.items()]


def discover_openstack_nodes(conn_details, conf):
    """Discover vms running in openstack
    :param conn_details - dict with openstack connection details -
        auth_url, api_key (password), username
    """
    client = Client(version='1.1', **conn_details)
    nodes = []
    if conf.get('discover'):
        vms_to_discover = conf['discover'].get('vm')
        if vms_to_discover:
            nodes.extend(discover_vms(client, vms_to_discover))
        services_to_discover = conf['discover'].get('nodes')
        if services_to_discover:
            nodes.extend(discover_services(client, services_to_discover))
    if conf.get('start'):
        vms = start_test_vms(client, conf['start'])
        nodes.extend(vms)

    return nodes


def start_test_vms(client, opts):

    user = opts.pop("user", None)
    key_file = opts.pop("key_file", None)
    aff_group = opts.pop("aff_group", None)
    raw_count = opts.pop('count')

    if raw_count.startswith("x"):
        logger.debug("Getting amount of compute services")
        count = len(client.services.list(binary="nova-compute"))
        count *= int(raw_count[1:])
    else:
        count = int(raw_count)

    if aff_group is not None:
        scheduler_hints = {'group': aff_group}
    else:
        scheduler_hints = None

    opts['scheduler_hints'] = scheduler_hints

    logger.debug("Will start {0} vms".format(count))

    nodes = create_vms_mt(client, count, **opts)
    return [node.Node(get_floating_ip(server), ["test_vm"], username=user,
                      key_path=key_file) for server in nodes]
