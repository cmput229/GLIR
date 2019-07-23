var schools = new Map();
var citiesTowns = new Map();
var campaigns = new Map();

$(document).ready(function() {
     // initiate autocomplete feature
    readSchools();
    attachSchools();
    readCitiesTowns();
    attachCitiesTowns();

    $('div#province-row').find('select').change(function() {
        attachSchools();
        attachCitiesTowns();
    });
	
	$('.singleclick option').mousedown(function(e) {
		e.preventDefault();
		var originalScrollTop = $(this).parent().scrollTop();
		console.log(originalScrollTop);
		$(this).prop('selected', $(this).prop('selected') ? false : true);
		var self = this;
		$(this).parent().focus();
		setTimeout(function() {
			$(self).parent().scrollTop(originalScrollTop);
		}, 0);
		
		return false;
	});
});

function attachSchools() {
    var province = $('#state').find(':selected').val();
    //console.log("province: " + province);
    
    if(schools[province] == null) {
        readSchools();
    };

    $('#current-school-nr-row').find('input').autocomplete({
      source: schools[province]
    });
    //console.log("schools: " + schools[province]);
}

function attachCitiesTowns() {
    var province = $('#state').find(':selected').val();
    //console.log("province: " + province);
    
    if(citiesTowns[province] == null) {
        readCitiesTowns();
    };

    $('#city-row').find('input').autocomplete({
      source: citiesTowns[province]
    });
    //console.log("citiesTowns: " + schools[province]);
}

function readSchools() {
    $.ajax({
        url: "data/ps-schools.json",
        dataType: "text",
        success: function(data) {
            var maps = $.parseJSON(data);
            for(i = 0; i < maps.length; i++) {
                schools[maps[i].province] = maps[i].hs;
                //console.log('reading: ' + maps[i].province);
                //console.log('reading: ' + maps[i].hs);
            }
        }   
    });
}

function readCitiesTowns() {
    $.ajax({
        url: "data/cities_towns_canada.json",
        dataType: "text",
        success: function(data) {
            var maps = $.parseJSON(data);
            for(i = 0; i < maps.length; i++) {
                citiesTowns[maps[i].province] = maps[i].citiesTowns;
                //console.log('reading: ' + maps[i].province);
                //console.log('reading: ' + maps[i].citiesTowns);
            }
        }   
    });
}



function careerSelectionChange() {
	var career = $('#00Nf100000BlvsS').val();
	if (career === 'HS' || career === 'PSE') {
		document.getElementById('faculty-interest-uai-row').style.display = 'block';
		document.getElementById('hs-curriculum-uai-row').style.display = 'block';
		document.getElementById('00Nf100000CZXIr').required = true;
		document.getElementById('00Nj000000A6Ii3').required = true;
		
	} else if (career === 'GRAD') {
		document.getElementById('faculty-interest-uai-row').style.display = 'block';
		document.getElementById('00Nj000000A6Ii3').required = true;
		
		document.getElementById('hs-curriculum-uai-row').style.display = 'none';
		document.getElementById('00Nf100000CZXIr').value = '';
		document.getElementById('00Nf100000CZXIr').required = false;
		
		document.getElementById('cad-curriculum-uai-row').style.display = 'none';
		document.getElementById('00Nf100000CZXIw').value = '';
		document.getElementById('00Nf100000CZXIw').required = false;
		
	} else	{
		document.getElementById('faculty-interest-uai-row').style.display = 'none';
		document.getElementById('00Nj000000A6Ii3').value = '';
		document.getElementById('00Nj000000A6Ii3').required = false;
		
		document.getElementById('hs-curriculum-uai-row').style.display = 'none';
		document.getElementById('00Nf100000CZXIr').value = '';
		document.getElementById('00Nf100000CZXIr').required = false;
		
		document.getElementById('cad-curriculum-uai-row').style.display = 'none';
		document.getElementById('00Nf100000CZXIw').value = '';
		document.getElementById('00Nf100000CZXIw').required = false;
	}
}

function curriculumSelectionChange() {
	var curriculum = $('#00Nf100000CZXIr').val();
	if (curriculum === 'Canada Grade 12 System') {
		document.getElementById('cad-curriculum-uai-row').style.display = 'block';
		document.getElementById('00Nf100000CZXIw').required = true;
	} else {
		document.getElementById('cad-curriculum-uai-row').style.display = 'none';
		document.getElementById('00Nf100000CZXIw').value = '';
		document.getElementById('00Nf100000CZXIw').required = false;
		
	}
}

function validate() {
	var filter = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,})+$/;
    if (!filter.test(document.getElementById('email').value)) {
		alert('Please provide a valid email address');
		email.focus;
		return false;
	}
}
