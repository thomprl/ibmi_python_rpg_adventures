let notificationTimeout; 

function showNotification(message, type) {
    const notification = document.getElementById('notification');
    const messageElement = document.getElementById('notification-message');
    const modal = document.getElementById('productModal');
    
    // Clear any existing timeout
    if (notificationTimeout) {
        clearTimeout(notificationTimeout);
    }

    // Remove previous type classes
    notification.classList.remove('success', 'error');

    // Add new type class
    notification.classList.add(type);

    // Position notification based on modal visibility
    if (modal.style.display === 'block') {
        notification.classList.add('over-modal');
    } else {
        notification.classList.remove('over-modal');
    }

    messageElement.textContent = message;
    notification.style.display = 'block';

    // Auto-hide after 10 seconds
    notificationTimeout = setTimeout(hideNotification, 10000);
}

function hideNotification() {
    const notification = document.getElementById('notification');
    notification.style.display = 'none';
    notification.classList.remove('over-modal');

    // Clear the timeout when manually closing
    if (notificationTimeout) {
        clearTimeout(notificationTimeout);
        notificationTimeout = null;
    }    
}

function deleteProduct(productNumber) {
    if (confirm(`Are you sure you want to delete product: ${productNumber}?`)) {
        $.ajax({
            url: '/api',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({
                app: 'product',
                action: 'delete',
                productnumber: productNumber
            }),
            success: function (response) {
                if (response.success) {
                    $('#myTable').DataTable().ajax.reload();
                    showNotification(response.message, 'success');
                } else {
                    showNotification(response.message, 'error');
                }
            },
            error: function (xhr, status, error) {
                showNotification('Error deleting product: ' + error, 'error');
            }
        });
    }
}

// Modal logic
function openProductModal(productNumber) {
    // Clear all form fields first
    $('#modalProductNumber').val('');
    $('#modalDescription').val('');
    $('#modalCost').val('');
    $('#modalUOM').val('');
    $('#modalCategory').val('');

    document.getElementById('productModal').style.display = 'block';
    if (productNumber) {
        // Edit mode
        $('#modalTitle').text('Edit Product');
        $('#modalProductNumber').prop('readonly', true);
        $.ajax({
            url: `/api?app=product&action=getproduct&productnumber=${productNumber}`,
            type: 'GET',
            success: function (response) {
                // response.data contains the product record
                const product = response.data;
                $('#modalProductNumber').val(product.ProductNumber);
                $('#modalDescription').val(product.Description);
                $('#modalCost').val(product.Cost);
                $('#modalUOM').val(product.UnitOfMeasure);
                $('#modalCategory').val(product.Category);
            },
            error: function () {
                showNotification('Error retrieving product.', 'error');
                closeProductModal();
            }
        });
    } else {
        // Add mode
        $('#modalTitle').text('Add Product');
        $('#modalProductNumber').prop('readonly', false).val('');
        $('#modalDescription').val('');
        $('#modalCost').val('');
        $('#modalUOM').val('');
        $('#modalCategory').val('');
    }
}

function closeProductModal() {
    document.getElementById('productModal').style.display = 'none';
}

function submitProductForm() {
    // Force cost to 0 if blank
    if ($('#modalCost').val() === '') {
        $('#modalCost').val(0);
    }
    let action = $('#modalTitle').text().startsWith('Edit') ? 'updateproduct' : 'addproduct';
    const productData = {
        app: 'product',
        action: action,
        ProductNumber: $('#modalProductNumber').val(),
        Description: $('#modalDescription').val(),
        Cost: $('#modalCost').val(),
        UnitOfMeasure: $('#modalUOM').val(),
        Category: $('#modalCategory').val()
    };

    $.ajax({
        url: '/api',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify(productData),
        success: function (response) {
            if (response.success) {
                $('#myTable').DataTable().ajax.reload();
                showNotification(response.message, 'success');
                closeProductModal();
            } else {
                showNotification(response.message, 'error');
            }
        },
        error: function (xhr, status, error) {
            showNotification('Error saving product: ' + error, 'error');
        }
    });
}

$(document).ready(function () {
    var table = $('#myTable').DataTable({
        ajax: {
            url: '/api?app=product&action=getproductlist',
            type: 'GET',
            dataSrc: 'data'
        },
        columns: [
            { 'data': 'ProductNumber' },
            { 'data': 'Description' },
            { 'data': 'Cost' },
            { 'data': 'UnitOfMeasure' },
            { 'data': 'Category' },
            {
                'data': null,
                'render': function (data, type, row) {
                    return `
                                <div class="action-buttons">
                                    <i class="fas fa-edit" title="Edit" onclick="openProductModal('${row.ProductNumber}')"></i>
                                    <i class="fas fa-trash-alt" onclick="deleteProduct('${row.ProductNumber}')" title="Delete"></i>
                                </div>                            
                            `;
                }
            }
        ],
        pageLength: 10,
        order: [[1, 'asc']]
    });
});

// Add this function near the other modal functions
function addNewProduct() {
    openProductModal(); // Call existing openProductModal with no parameters
}