"""
Prometheus client.

This module handles interactions with Prometheus-compatible services using
the prometrix library. Supported backends include:

- Prometheus (vanilla)
- Amazon Managed Prometheus (AMP)
- Azure Managed Prometheus
- Coralogix
- Victoria Metrics
- Thanos

Key features:
- Multi-provider support via prometrix
- Prometheus query execution (instant and range)
- Error handling with retries
- Metric data parsing
"""

from datetime import datetime

from prometrix import (
    AWSPrometheusConfig,
    AzurePrometheusConfig,
    CoralogixPrometheusConfig,
    CustomPrometheusConnect,
    PrometheusConfig,
    VictoriaMetricsPrometheusConfig,
    get_custom_prometheus_connect,
)

from .logger import logger
from .utils import handle_exceptions

# Map of provider names to their config classes for easy lookup
PROVIDER_CONFIGS = {
    "prometheus": PrometheusConfig,
    "aws": AWSPrometheusConfig,
    "azure": AzurePrometheusConfig,
    "coralogix": CoralogixPrometheusConfig,
    "victoria_metrics": VictoriaMetricsPrometheusConfig,
}


def create_prometheus_client(
    url: str,
    provider: str = "prometheus",
    **kwargs: object,
) -> "PrometheusClient":
    """Create a PrometheusClient for the given provider.

    This factory function simplifies creating a client by selecting the
    appropriate prometrix config class based on the provider name.

    Args:
        url: The Prometheus-compatible endpoint URL.
        provider: One of 'prometheus', 'aws', 'azure', 'coralogix',
            or 'victoria_metrics'.
        **kwargs: Additional keyword arguments forwarded to the provider's
            config class (e.g. ``aws_region`` for AMP, ``azure_resource``
            for Azure).

    Returns:
        A configured PrometheusClient instance.

    Raises:
        ValueError: If the provider is not supported.
    """
    config_cls = PROVIDER_CONFIGS.get(provider)
    if config_cls is None:
        supported = ", ".join(sorted(PROVIDER_CONFIGS))
        raise ValueError(f"Unsupported provider '{provider}'. Supported: {supported}")

    config = config_cls(url=url, **kwargs)
    return PrometheusClient(config=config)


class PrometheusClient:
    """Prometheus-compatible query client backed by prometrix.

    Wraps :class:`prometrix.CustomPrometheusConnect` to provide a simple
    interface for instant and range PromQL queries against any
    Prometheus-compatible backend.

    Args:
        config: A prometrix config object (e.g. ``PrometheusConfig``,
            ``AWSPrometheusConfig``, etc.).
    """

    @handle_exceptions
    def __init__(self, config: PrometheusConfig) -> None:
        logger.debug(
            f"Initializing PrometheusClient with provider "
            f"{type(config).__name__} at {config.url}"
        )
        self.config = config
        self._client: CustomPrometheusConnect = get_custom_prometheus_connect(config)

        # Verify connectivity
        self._client.check_prometheus_connection()
        logger.debug("Successfully initialized PrometheusClient with valid connection")

    @handle_exceptions
    def query(self, query: str) -> list:
        """Execute an instant PromQL query.

        Args:
            query: The PromQL query string.

        Returns:
            A list of metric result dicts as returned by Prometheus.
        """
        logger.debug(f"Executing instant query: {query}")
        result = self._client.custom_query(query=query)
        logger.debug(f"Query successful, received {len(result)} result(s)")
        return result

    @handle_exceptions
    def query_range(
        self,
        query: str,
        start_time: datetime,
        end_time: datetime,
        step: str,
    ) -> list:
        """Execute a range PromQL query.

        Args:
            query: The PromQL query string.
            start_time: Start of the query range.
            end_time: End of the query range.
            step: Step interval for data points (e.g. ``'5m'``).

        Returns:
            A list of metric result dicts as returned by Prometheus.
        """
        logger.debug(f"Executing range query: {query}")
        logger.debug(f"Time range: {start_time} to {end_time}, step: {step}")

        result = self._client.custom_query_range(
            query=query,
            start_time=start_time,
            end_time=end_time,
            step=step,
        )
        data_points = len(result[0].get("values", [])) if result else 0
        logger.debug(f"Range query successful, received {data_points} data points")
        return result

    @handle_exceptions
    def get_pod_names(self, namespace: str, deployment: str) -> list:
        """Get list of pod names for a deployment.

        Args:
            namespace: Kubernetes namespace.
            deployment: Deployment name.

        Returns:
            A list of dicts with pod ``name`` keys.
        """
        logger.debug(
            f"Getting pod names for deployment {deployment} in namespace {namespace}"
        )
        query = f'''kube_pod_info{{
            namespace="{namespace}",
            pod=~"{deployment}-[a-z0-9]+-[a-z0-9]+"
        }}'''

        result = self.query(query)
        pods = [{"name": pod["metric"]["pod"]} for pod in result]

        logger.debug(f"Found {len(pods)} pods for deployment {deployment}")
        return pods

    @handle_exceptions
    def get_cluster_name(self) -> str:
        """Get the EKS cluster name from node labels.

        Returns:
            The cluster name, or an empty string if not found.
        """
        logger.debug("Querying for EKS cluster name")
        query = 'kube_node_labels{label_eks_amazonaws_com_cluster!=""}'
        result = self.query(query)

        if not result:
            logger.warning("No cluster name found in node labels")
            return ""

        cluster_name = result[0]["metric"]["label_eks_amazonaws_com_cluster"]
        logger.debug(f"Found cluster name: {cluster_name}")
        return cluster_name
