// Update only this service's shortcut while retaining the other pbs settings.
ObjC.import('Foundation');

function run(argv) {
  if (argv.length !== 1) throw new Error('Expected one macOS key equivalent');
  const defaults = $.NSUserDefaults.standardUserDefaults;
  const domainName = $('pbs');
  const serviceName = $('(null) - NvimAnywhere - runWorkflowAsService');
  const existingDomain = defaults.persistentDomainForName(domainName);
  const domain = existingDomain.isNil() ? $.NSMutableDictionary.alloc.init : existingDomain.mutableCopy;
  const existingServices = domain.objectForKey('NSServicesStatus');
  const services = existingServices.isNil() ? $.NSMutableDictionary.alloc.init : existingServices.mutableCopy;
  const existingService = services.objectForKey(serviceName);
  const service = existingService.isNil() ? $.NSMutableDictionary.alloc.init : existingService.mutableCopy;
  service.setObjectForKey($(argv[0]), 'key_equivalent');
  services.setObjectForKey(service, serviceName);
  domain.setObjectForKey(services, 'NSServicesStatus');
  defaults.setPersistentDomainForName(domain, domainName);
  defaults.synchronize;
}
